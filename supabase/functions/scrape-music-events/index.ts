// Roatán Insider — Music & events scraper.
//
// Pulls the weekly live-music schedule from Blue Wave Radio's Roatán Music
// Scene (bluewaveradio.live/roatanmusicscene — Keith's data, used with his
// permission), normalizes it into the iOS app's `Event` schema, and uploads
// the JSON to Supabase Storage at `app-data/events.json`.
//
// The page itself is a Squarespace shell; the schedule is served by Keith's
// Google Apps Script as a JSONP payload (`renderSchedule("<html>")`). We call
// that endpoint directly — same data the website renders, no HTML-page
// scraping, no ScrapingBee needed. The payload markup is machine-generated
// from his spreadsheet, so its structure is stable.
//
// Safety: if parsing yields fewer than MIN_EVENTS rows, ABORT without
// overwriting the existing events.json, and upload the raw payload to
// `app-data/music_debug.txt` for inspection. Either way, write
// `app-data/music_status.json` so pipeline health is observable.
//
// Trigger: pg_cron, daily at 09:10 and 15:10 UTC.
//
// Deploy: supabase functions deploy scrape-music-events

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// --- Schema (must match RoatanInsider/Models/Event.swift) -------------------

interface AppEvent {
  id: string;
  venue: string;
  area: string;
  category: string;
  performer: string;
  day: string | null;      // "monday" ... "sunday"
  date: string | null;     // "yyyy-MM-dd" for dated one-offs
  startTime: string;       // 24hr "HH:mm"
  genre: string | null;
  notes: string | null;
  recurring: boolean;
  recurringRule: string | null;
  specialEvent: boolean;
  featured: boolean;
  contact: string | null;
  active: boolean;
}

// --- Source ------------------------------------------------------------------

// Keith's Apps Script endpoint, extracted from bluewaveradio.live/roatanmusicscene.
// If Blue Wave redeploys the script this ID changes — fetch the page and look
// for `var EXEC = "https://script.google.com/macros/s/..."` to update it.
const BWR_EXEC =
  "https://script.google.com/macros/s/AKfycbyiSCqAqpaeDEFiLC4DeWKP1eaPd4AbeIdukf3JfnBwcU4EQU9Z0Vq4nQQdkzyCs7UGOw/exec";
const BWR_PAGE = "https://www.bluewaveradio.live/roatanmusicscene";

const MIN_EVENTS = 15;

// Keith's category labels → the app's EventCategory raw values.
const CATEGORY_MAP: Record<string, string> = {
  "LIVE MUSIC": "Live Music",
  "LIVE DJ": "DJ",
  "DJ": "DJ",
  "KARAOKE NIGHT": "Karaoke",
  "KARAOKE": "Karaoke",
  "TRIVIA NIGHT": "Trivia",
  "TRIVIA": "Trivia",
  "MUSIC TRIVIA": "Trivia",
  "BINGO NIGHT": "Game Night",
  "BINGO": "Game Night",
  "GAME NIGHT": "Game Night",
  "MOVIE NIGHT": "Movie Night",
  "FAMILY NIGHT": "Family Event",
  "GARIFUNA SHOW": "Cultural Event",
  "FIRE SHOW": "Fire Show",
  "DANCE SHOW": "Dance Show",
  "EVENT": "Special Event",
};

// Josh's curated "Don't Miss" picks. The feed carries no editorial signal, so
// featured status is re-applied here by (day, venue substring, startTime).
const FEATURED: { day: string; venue: string; time: string }[] = [
  { day: "monday",    venue: "sundowners", time: "17:00" },
  { day: "tuesday",   venue: "sundowners", time: "17:00" },
  { day: "wednesday", venue: "sundowners", time: "19:00" },
  { day: "thursday",  venue: "bananarama", time: "17:30" },
  { day: "thursday",  venue: "sundowners", time: "19:00" },
  { day: "friday",    venue: "sundowners", time: "19:00" },
  { day: "saturday",  venue: "sundowners", time: "18:30" },
  { day: "sunday",    venue: "bananarama", time: "18:00" },
  { day: "sunday",    venue: "sundowners", time: "14:00" },
];

// Blue Wave groups everything east of West End as one bucket; the venue line
// carries the real area ("Blue Bahia Beach Grill, Sandy Bay | +504 ..."), so
// data-area is only the fallback.
const AREA_FALLBACK: Record<string, string> = {
  "Sandy Bay & Beyond": "Sandy Bay",
};

// --- Fetch + JSONP unwrap -----------------------------------------------------

async function fetchScheduleHtml(): Promise<string> {
  const url = `${BWR_EXEC}?fn=embed_js&cb=renderSchedule&v=BWR-JSONP-v9&ts=${Date.now()}`;
  const res = await fetch(url, { redirect: "follow" });
  if (!res.ok) throw new Error(`Apps Script fetch failed: HTTP ${res.status}`);
  const body = await res.text();

  const start = body.indexOf('renderSchedule("');
  const end = body.lastIndexOf('")');
  if (start < 0 || end <= start) {
    throw new Error(`Unexpected JSONP shape (len=${body.length}, head=${body.slice(0, 80)})`);
  }
  const jsString = body.substring(start + 'renderSchedule("'.length, end);
  return unescapeJsString(jsString);
}

function unescapeJsString(s: string): string {
  return s.replace(/\\u([0-9a-fA-F]{4})|\\(.)/g, (_m, hex, ch) => {
    if (hex) return String.fromCharCode(parseInt(hex, 16));
    switch (ch) {
      case "n": return "\n";
      case "t": return "\t";
      case "r": return "\r";
      default: return ch; // \" \\ \/ etc.
    }
  });
}

function decodeEntities(s: string): string {
  return s
    .replace(/&#(\d+);/g, (_m, d) => String.fromCharCode(parseInt(d, 10)))
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ");
}

// --- Parse ---------------------------------------------------------------------

function parseEvents(html: string): AppEvent[] {
  // The payload repeats the schedule in three fragments (week / weekend /
  // today). Parse ONLY the full-week fragment to avoid duplicates.
  let week = html;
  const weekStart = html.indexOf('data-frag="week"');
  if (weekStart >= 0) {
    const weekendStart = html.indexOf('data-frag="weekend"', weekStart);
    week = html.substring(weekStart, weekendStart > 0 ? weekendStart : html.length);
  }

  const events: AppEvent[] = [];
  const sectionRe = /<section class="day" data-day="([A-Za-z]+)"[^>]*>([\s\S]*?)<\/section>/g;
  let sm: RegExpExecArray | null;
  while ((sm = sectionRe.exec(week)) !== null) {
    const day = sm[1].toLowerCase();
    const itemRe = /<li class="item"[^>]*data-area="([^"]*)"[^>]*>([\s\S]*?)<\/li>/g;
    let im: RegExpExecArray | null;
    while ((im = itemRe.exec(sm[2])) !== null) {
      const ev = parseItem(day, decodeEntities(im[1]), im[2]);
      if (ev) events.push(ev);
    }
  }

  // De-dupe (same slot can appear twice when Keith lists a dated override).
  const seen = new Set<string>();
  return events.filter((e) => {
    if (seen.has(e.id)) return false;
    seen.add(e.id);
    return true;
  });
}

function parseItem(day: string, dataArea: string, itemHtml: string): AppEvent | null {
  const venueMatch = itemHtml.match(/<span class="venue">([\s\S]*?)<\/span>/);
  if (!venueMatch) return null;
  const venueRaw = decodeEntities(venueMatch[1]).trim();

  // "Bananarama, West Bay | +504 9456-3382"
  const [venueAndArea, phoneRaw] = splitOnce(venueRaw, "|");
  const lastComma = venueAndArea.lastIndexOf(",");
  const venue = (lastComma > 0 ? venueAndArea.slice(0, lastComma) : venueAndArea).trim();
  const areaFromVenue = lastComma > 0 ? venueAndArea.slice(lastComma + 1).trim() : "";
  const area = areaFromVenue || AREA_FALLBACK[dataArea] || dataArea || "Roatán";
  const contact = phoneRaw ? phoneRaw.trim() : null;

  // Structured sub-spans first, then flatten the rest to text.
  const timeMatch = itemHtml.match(/class="time">\s*@?\s*(\d{1,2}):(\d{2})\s*([AP])\.?M/i);
  const dateMatch = itemHtml.match(/class="date">\s*\[(\d{1,2})\/(\d{1,2})\/(\d{4})\]/);

  // The addl span is reused for different things: "{ Every Monday }" is a
  // recurrence rule, "Guitar & Vocals" is instrumentation. Classify each.
  let recurrenceText: string | null = null;
  const extraInfo: string[] = [];
  const addlRe = /class="addl">\s*\{?\s*([^<}]+?)\s*\}?\s*</g;
  let am: RegExpExecArray | null;
  while ((am = addlRe.exec(itemHtml)) !== null) {
    const text = decodeEntities(am[1]).trim();
    if (!text) continue;
    if (/\b(every|daily|weekly|nightly)\b/i.test(text)) recurrenceText = text;
    else extraInfo.push(text);
  }

  if (!timeMatch) return null; // no start time — not a schedulable row
  let hour = parseInt(timeMatch[1], 10) % 12;
  if (timeMatch[3].toUpperCase() === "P") hour += 12;
  const startTime = `${String(hour).padStart(2, "0")}:${timeMatch[2]}`;

  let date = dateMatch
    ? `${dateMatch[3]}-${dateMatch[1].padStart(2, "0")}-${dateMatch[2].padStart(2, "0")}`
    : null;

  // Tail text: everything after the tail span opens, up to termsline, with
  // tags/brackets stripped. Yields "LIVE MUSIC · TOMMY MORRIS - Classics · ..."
  const tailStart = itemHtml.indexOf('class="tail">');
  if (tailStart < 0) return null;
  let tail = itemHtml.slice(tailStart + 'class="tail">'.length);
  const termsIdx = tail.indexOf('class="termsline"');
  if (termsIdx >= 0) {
    // Cut BEFORE the tag that carries the termsline class, not mid-attribute —
    // otherwise an unterminated "<div " survives tag-stripping as literal text.
    const tagOpen = tail.lastIndexOf("<", termsIdx);
    tail = tail.slice(0, tagOpen >= 0 ? tagOpen : termsIdx);
  }
  const tailText = decodeEntities(
    tail
      .replace(/<[^>]+>/g, " ")
      .replace(/@\s*\d{1,2}:\d{2}\s*[AP]\.?M\.?/gi, " ")
      .replace(/\[\d{1,2}\/\d{1,2}\/\d{4}\]/g, " ")
      .replace(/\{[^}]*\}/g, " ")
  ).replace(/\s+/g, " ").trim();

  const segments = tailText
    .split("·")
    .map((s) => s.trim())
    .filter((s) => s.length > 0 && !s.includes("<"));
  if (segments.length === 0) return null;

  const label = segments[0].toUpperCase().replace(/\s+/g, " ").trim();
  const category = CATEGORY_MAP[label] ?? "Special Event";

  // Keith sometimes tags this week's booking with a bracketed day-month
  // segment ("[5-Aug]") instead of the [m/d/yyyy] date span. Treat it as
  // the event's date and keep it out of the performer text.
  const dayMonthRe = /^\[?\s*(\d{1,2})-([A-Za-z]{3,4})\.?\s*\]?$/;
  for (const seg of segments.slice(1)) {
    const dm = seg.match(dayMonthRe);
    if (dm && !date) {
      const iso = dayMonthToIso(parseInt(dm[1], 10), dm[2]);
      if (iso) date = iso;
    }
  }

  // Performer segment: "TOMMY MORRIS - American & British Classics"
  let performer = "";
  let genre: string | null = null;
  const rest = segments.slice(1).filter(
    (s) => !/^CALL TO CONFIRM$/i.test(s) && !dayMonthRe.test(s)
  );
  const confirmNote = segments.slice(1).some((s) => /^CALL TO CONFIRM$/i.test(s))
    ? "Call to confirm" : null;
  if (rest.length > 0) {
    const [who, what] = splitOnce(rest[0].replace(/^New!\s*/i, ""), " - ");
    performer = titleCase(who.trim());
    genre = what ? what.trim() : null;
  }
  if (!performer) performer = category;
  const notes = [confirmNote, ...rest.slice(1).map((s) => titleCase(s))]
    .filter(Boolean).join(" · ") || null;

  if (extraInfo.length > 0) {
    genre = genre ? `${genre} · ${extraInfo.join(" · ")}` : extraInfo.join(" · ");
  }

  const recurring = date === null;
  const recurringRule = recurring
    ? (recurrenceText ?? `Every ${capitalize(day)}`)
    : null;

  const featured = FEATURED.some(
    (f) => f.day === day && venue.toLowerCase().includes(f.venue) && f.time === startTime
  );

  return {
    id: `${day.slice(0, 3)}-${slug(venue)}-${slug(performer)}-${startTime.replace(":", "")}${date ? "-" + date : ""}`,
    venue,
    area,
    category,
    performer,
    day,
    date,
    startTime,
    genre,
    notes,
    recurring,
    recurringRule,
    specialEvent: category === "Special Event",
    featured,
    contact,
    active: true,
  };
}

function splitOnce(s: string, sep: string): [string, string | null] {
  const i = s.indexOf(sep);
  return i < 0 ? [s, null] : [s.slice(0, i), s.slice(i + sep.length)];
}

const KEEP_UPPER = new Set(["DJ", "MC", "LCR", "II", "III", "TBA"]);
const KEEP_LOWER = new Set(["de", "la", "del", "y", "w/", "the", "and", "of"]);

function titleCase(s: string): string {
  return s.split(/\s+/).map((word, i) => {
    const bare = word.replace(/[^A-Za-z/]/g, "");
    if (KEEP_UPPER.has(bare.toUpperCase())) return word.toUpperCase();
    if (i > 0 && KEEP_LOWER.has(bare.toLowerCase())) return word.toLowerCase();
    return word
      .split("-")
      .map((p) => (p ? p.charAt(0).toUpperCase() + p.slice(1).toLowerCase() : p))
      .join("-");
  }).join(" ");
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

const MONTH_NUM: Record<string, number> = {
  jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6,
  jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12,
};

/// "5" + "Aug" → "2026-08-05". Year inferred: month >= current month →
/// this year, otherwise next year (island time).
function dayMonthToIso(day: number, monthName: string): string | null {
  const month = MONTH_NUM[monthName.slice(0, 3).toLowerCase()];
  if (!month || day < 1 || day > 31) return null;
  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const year = month >= currentMonth ? now.getFullYear() : now.getFullYear() + 1;
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40);
}

// --- Upload ------------------------------------------------------------------

function storageClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) throw new Error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing");
  return createClient(supabaseUrl, serviceKey);
}

async function upload(path: string, body: string, contentType: string): Promise<void> {
  const { error } = await storageClient().storage
    .from("app-data")
    .upload(path, new Blob([body], { type: contentType }), {
      upsert: true,
      cacheControl: "300",
      contentType,
    });
  if (error) throw new Error(`Upload ${path} failed: ${error.message}`);
}

async function writeStatus(ok: boolean, detail: Record<string, unknown>): Promise<void> {
  try {
    await upload(
      "music_status.json",
      JSON.stringify({ ok, lastRun: new Date().toISOString(), source: BWR_PAGE, ...detail }, null, 2),
      "application/json"
    );
  } catch (err) {
    console.error(`Failed to write music_status.json: ${err}`);
  }
}

// --- Handler -------------------------------------------------------------------

Deno.serve(async (_req) => {
  try {
    const html = await fetchScheduleHtml();
    const events = parseEvents(html);

    if (events.length < MIN_EVENTS) {
      console.error(`Parsed only ${events.length} events (min ${MIN_EVENTS}) — aborting, not overwriting.`);
      try { await upload("music_debug.txt", html, "text/plain"); } catch (e) {
        console.error(`Debug upload failed: ${e}`);
      }
      await writeStatus(false, { count: events.length, error: `Parsed ${events.length} events; below safety floor of ${MIN_EVENTS}. Debug payload uploaded.` });
      throw new Error(`Parsed only ${events.length} events. Source markup may have changed.`);
    }

    await upload("events.json", JSON.stringify(events, null, 2), "application/json");
    const summary = {
      count: events.length,
      recurring: events.filter((e) => e.recurring).length,
      dated: events.filter((e) => e.date !== null).length,
      featured: events.filter((e) => e.featured).length,
    };
    await writeStatus(true, summary);

    return new Response(JSON.stringify({ ok: true, ...summary }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("scrape-music-events failed:", err);
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
