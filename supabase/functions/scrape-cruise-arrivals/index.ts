// Roatán Insider — Daily cruise arrivals scraper.
//
// Pulls upcoming cruise ship arrivals to Roatán, normalizes them into the
// schema the iOS app expects, and uploads the JSON to Supabase Storage at
// `app-data/cruise_arrivals.json`.
//
// Strategy:
//   1. PRIMARY: read Keith's public Google Sheet (tab `cruise_schedule`)
//      via the gviz JSON API — structured rows, no HTML parsing.
//   2. FALLBACK: scrape the rendered schedule pages (direct fetch, then
//      ScrapingBee JS rendering when blocked; env: SCRAPINGBEE_API_KEY).
//   3. If both paths yield zero rows, ABORT — never overwrite a good
//      file with empty data. Upload debug HTML + failure status instead.
//
// Trigger: pg_cron, daily at 09:00 and 15:00 UTC.
//
// Deploy:
//   supabase functions deploy scrape-cruise-arrivals

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// --- Schema -----------------------------------------------------------------

interface CruiseArrival {
  id: string;
  shipName: string;
  cruiseLine: string | null;
  port: string;
  date: string;        // ISO YYYY-MM-DD
  arrivalTime: string; // HH:mm 24hr
  departureTime: string;
  passengerCount: number;
  notes?: string;
}

// --- Passenger capacity lookup ----------------------------------------------
// Published double-occupancy figures from cruise-line spec sheets. Used only
// when the sheet has no passenger figure for a row, and as a page-validation
// signal in the HTML fallback path.

const SHIP_CAPACITY: Record<string, { capacity: number; line: string }> = {
  // Carnival fleet (dock at Mahogany Bay — Carnival's private port)
  "Carnival Vista":        { capacity: 3934, line: "Carnival" },
  "Carnival Horizon":      { capacity: 3954, line: "Carnival" },
  "Carnival Panorama":     { capacity: 3954, line: "Carnival" },
  "Carnival Magic":        { capacity: 3690, line: "Carnival" },
  "Carnival Dream":        { capacity: 3646, line: "Carnival" },
  "Carnival Breeze":       { capacity: 3690, line: "Carnival" },
  "Carnival Sunshine":     { capacity: 3002, line: "Carnival" },
  "Carnival Sunrise":      { capacity: 2974, line: "Carnival" },
  "Carnival Glory":        { capacity: 2974, line: "Carnival" },
  "Carnival Conquest":     { capacity: 2974, line: "Carnival" },
  "Carnival Liberty":      { capacity: 2974, line: "Carnival" },
  "Carnival Freedom":      { capacity: 2974, line: "Carnival" },
  "Carnival Valor":        { capacity: 2974, line: "Carnival" },
  "Carnival Miracle":      { capacity: 2124, line: "Carnival" },
  "Carnival Pride":        { capacity: 2124, line: "Carnival" },
  "Carnival Spirit":       { capacity: 2124, line: "Carnival" },
  "Carnival Legend":       { capacity: 2124, line: "Carnival" },
  "Carnival Paradise":     { capacity: 2124, line: "Carnival" },
  "Mardi Gras":            { capacity: 5282, line: "Carnival" },
  "Carnival Celebration":  { capacity: 5282, line: "Carnival" },
  "Carnival Jubilee":      { capacity: 5282, line: "Carnival" },
  "Carnival Radiance":     { capacity: 2974, line: "Carnival" },

  // Royal Caribbean (dock at Port of Roatán / Coxen Hole)
  "Allure of the Seas":        { capacity: 5484, line: "Royal Caribbean" },
  "Oasis of the Seas":         { capacity: 5484, line: "Royal Caribbean" },
  "Symphony of the Seas":      { capacity: 5518, line: "Royal Caribbean" },
  "Harmony of the Seas":       { capacity: 5479, line: "Royal Caribbean" },
  "Wonder of the Seas":        { capacity: 5734, line: "Royal Caribbean" },
  "Icon of the Seas":          { capacity: 5610, line: "Royal Caribbean" },
  "Utopia of the Seas":        { capacity: 5668, line: "Royal Caribbean" },
  "Liberty of the Seas":       { capacity: 3634, line: "Royal Caribbean" },
  "Freedom of the Seas":       { capacity: 3634, line: "Royal Caribbean" },
  "Independence of the Seas":  { capacity: 3634, line: "Royal Caribbean" },
  "Voyager of the Seas":       { capacity: 3286, line: "Royal Caribbean" },
  "Mariner of the Seas":       { capacity: 3344, line: "Royal Caribbean" },
  "Navigator of the Seas":     { capacity: 3286, line: "Royal Caribbean" },
  "Adventure of the Seas":     { capacity: 3114, line: "Royal Caribbean" },
  "Explorer of the Seas":      { capacity: 3286, line: "Royal Caribbean" },
  "Brilliance of the Seas":    { capacity: 2543, line: "Royal Caribbean" },
  "Radiance of the Seas":      { capacity: 2466, line: "Royal Caribbean" },
  "Jewel of the Seas":         { capacity: 2466, line: "Royal Caribbean" },
  "Enchantment of the Seas":   { capacity: 2252, line: "Royal Caribbean" },
  "Grandeur of the Seas":      { capacity: 1992, line: "Royal Caribbean" },
  "Rhapsody of the Seas":      { capacity: 2000, line: "Royal Caribbean" },
  "Star of the Seas":          { capacity: 5610, line: "Royal Caribbean" },
  "Serenade of the Seas":      { capacity: 2466, line: "Royal Caribbean" },

  // Norwegian (Port of Roatán)
  "Norwegian Joy":      { capacity: 3804, line: "Norwegian" },
  "Norwegian Bliss":    { capacity: 4004, line: "Norwegian" },
  "Norwegian Encore":   { capacity: 3998, line: "Norwegian" },
  "Norwegian Getaway":  { capacity: 3963, line: "Norwegian" },
  "Norwegian Escape":   { capacity: 4248, line: "Norwegian" },
  "Norwegian Breakaway": { capacity: 3963, line: "Norwegian" },
  "Norwegian Epic":     { capacity: 4100, line: "Norwegian" },
  "Norwegian Pearl":    { capacity: 2394, line: "Norwegian" },
  "Norwegian Jade":     { capacity: 2402, line: "Norwegian" },
  "Norwegian Jewel":    { capacity: 2376, line: "Norwegian" },
  "Norwegian Star":     { capacity: 2348, line: "Norwegian" },
  "Norwegian Spirit":   { capacity: 2018, line: "Norwegian" },
  "Norwegian Dawn":     { capacity: 2340, line: "Norwegian" },
  "Norwegian Prima":    { capacity: 3215, line: "Norwegian" },
  "Norwegian Viva":     { capacity: 3215, line: "Norwegian" },

  // MSC (Port of Roatán)
  "MSC Seascape":   { capacity: 4540, line: "MSC" },
  "MSC Seashore":   { capacity: 4540, line: "MSC" },
  "MSC Meraviglia": { capacity: 4488, line: "MSC" },
  "MSC Bellissima": { capacity: 4488, line: "MSC" },
  "MSC Divina":     { capacity: 3502, line: "MSC" },
  "MSC Magnifica":  { capacity: 2518, line: "MSC" },
  "MSC Poesia":     { capacity: 2550, line: "MSC" },
  "MSC Orchestra":  { capacity: 2550, line: "MSC" },
  "MSC Musica":     { capacity: 2550, line: "MSC" },
  "MSC Armonia":    { capacity: 2199, line: "MSC" },
  "MSC Sinfonia":   { capacity: 2199, line: "MSC" },

  // Holland America (Port of Roatán)
  "Eurodam":          { capacity: 2104, line: "Holland America" },
  "Nieuw Amsterdam":  { capacity: 2106, line: "Holland America" },
  "Rotterdam":        { capacity: 2668, line: "Holland America" },
  "Zuiderdam":        { capacity: 1916, line: "Holland America" },
  "Oosterdam":        { capacity: 1916, line: "Holland America" },
  "Westerdam":        { capacity: 1916, line: "Holland America" },
  "Noordam":          { capacity: 1972, line: "Holland America" },
  "Koningsdam":       { capacity: 2650, line: "Holland America" },
  "Nieuw Statendam":  { capacity: 2666, line: "Holland America" },

  // Princess (Port of Roatán)
  "Discovery Princess": { capacity: 3660, line: "Princess" },
  "Enchanted Princess": { capacity: 3660, line: "Princess" },
  "Sky Princess":       { capacity: 3660, line: "Princess" },
  "Caribbean Princess": { capacity: 3140, line: "Princess" },
  "Crown Princess":     { capacity: 3080, line: "Princess" },
  "Ruby Princess":      { capacity: 3080, line: "Princess" },
  "Emerald Princess":   { capacity: 3080, line: "Princess" },
  "Regal Princess":     { capacity: 3560, line: "Princess" },
  "Royal Princess":     { capacity: 3560, line: "Princess" },

  // Disney (Port of Roatán)
  "Disney Magic":   { capacity: 2700, line: "Disney" },
  "Disney Wonder":  { capacity: 2700, line: "Disney" },
  "Disney Dream":   { capacity: 4000, line: "Disney" },
  "Disney Fantasy": { capacity: 4000, line: "Disney" },
  "Disney Wish":    { capacity: 4000, line: "Disney" },
  "Disney Treasure": { capacity: 4000, line: "Disney" },
};

// --- Primary source: Keith's Google Sheet ------------------------------------
// theroatandirectory.com renders its cruise schedule client-side from a
// public Google Sheet (spreadsheet "1Z1XVw...", tab "cruise_schedule").
// Reading the sheet directly via the gviz JSON API gives us structured rows
// (Date, Ship Name, Cruise Line, Arrive, Depart, Passengers, Notes) with no
// HTML parsing at all — Keith maintains it daily and Josh has his explicit
// permission. The HTML-scrape path below is kept only as a fallback.

const SHEET_ID = "1Z1XVw4Ya2fhvGZHYk27QXQgxvF1DNJa11i7CLUbvMnc";
const SHEET_TAB = "cruise_schedule";
const SHEET_LABEL = `google-sheet:${SHEET_TAB}`;

async function fetchSheetArrivals(): Promise<CruiseArrival[]> {
  const url = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:json&headers=1&sheet=${encodeURIComponent(SHEET_TAB)}`;
  const res = await fetch(url, { headers: BROWSER_HEADERS });
  if (!res.ok) throw new Error(`Sheet fetch failed: HTTP ${res.status}`);
  const text = await res.text();

  // Response shape: google.visualization.Query.setResponse({...});
  const start = text.indexOf("(");
  const end = text.lastIndexOf(")");
  if (start < 0 || end <= start) throw new Error("Unexpected gviz response shape");
  const payload = JSON.parse(text.substring(start + 1, end));
  if (payload?.status !== "ok" || !payload?.table) {
    throw new Error(`gviz status: ${payload?.status ?? "missing table"}`);
  }

  const labels: string[] = payload.table.cols.map((c: { label?: string }) => (c.label ?? "").toLowerCase());
  const idx = (name: string) => labels.findIndex((l) => l.includes(name));
  const iDate = idx("date"), iShip = idx("ship"), iLine = idx("line");
  const iArr = idx("arrive"), iDep = idx("depart"), iPax = idx("passenger"), iNotes = idx("note");
  if (iDate < 0 || iShip < 0) throw new Error(`Sheet columns changed: ${labels.join(", ")}`);

  const today = todayISO();
  const arrivals: CruiseArrival[] = [];
  for (const row of payload.table.rows ?? []) {
    const c = row.c ?? [];
    const date: string = c[iDate]?.f ?? "";
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || date < today) continue;
    const shipName = String(c[iShip]?.v ?? "").trim();
    if (!shipName) continue;

    const cruiseLine = iLine >= 0 && c[iLine]?.v ? String(c[iLine].v).trim() : null;
    const pax = iPax >= 0 && typeof c[iPax]?.v === "number"
      ? Math.round(c[iPax].v)
      : SHIP_CAPACITY[shipName]?.capacity ?? 3000;
    const notes = iNotes >= 0 && c[iNotes]?.v ? String(c[iNotes].v).trim() : undefined;
    const port = /carnival/i.test(cruiseLine ?? shipName) ? "Mahogany Bay" : "Port of Roatán";

    arrivals.push({
      id: `${date}-${slug(shipName)}-${slug(port)}`,
      shipName,
      cruiseLine,
      port,
      date,
      arrivalTime: padTime(c[iArr]?.f ?? "07:00"),
      departureTime: padTime(c[iDep]?.f ?? "16:00"),
      passengerCount: pax,
      ...(notes ? { notes } : {}),
    });
  }
  return dedupeAndSort(arrivals);
}

/// "7:00" → "07:00"; passes through anything already zero-padded.
function padTime(t: string): string {
  const m = t.match(/(\d{1,2}):(\d{2})/);
  if (!m) return t;
  return `${m[1].padStart(2, "0")}:${m[2]}`;
}

// --- Fallback fetching --------------------------------------------------------

// theroatandirectory.com is maintained daily by Keith Roberts (Blue Wave
// Radio); Josh has explicit permission to use his data. Try this first;
// fall back to public aggregators only if his site is unreachable.
const SOURCE_CANDIDATES = [
  "https://www.theroatandirectory.com/roatandailyevents",
  "https://cruisedig.com/ports/roatan-honduras",
  "https://www.cruisemapper.com/ports/roatan-island-port-29",
  "https://www.anacaribe.net/itinerary",
];

const BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
  "Accept-Encoding": "gzip, deflate, br",
  "DNT": "1",
  "Upgrade-Insecure-Requests": "1",
};

interface FetchResult {
  url: string;
  html: string;
  via: "direct" | "scrapingbee";
}

async function fetchPage(): Promise<FetchResult> {
  const errors: string[] = [];

  for (const url of SOURCE_CANDIDATES) {
    // Try 1: direct fetch with browser headers.
    try {
      const res = await fetch(url, { headers: BROWSER_HEADERS });
      if (res.ok) {
        const html = await res.text();
        if (looksLikeRealPage(html)) {
          console.log(`Direct fetch succeeded: ${url}`);
          return { url, html, via: "direct" };
        }
      }
      errors.push(`${url} (direct): ${res.status} or empty`);
    } catch (err) {
      errors.push(`${url} (direct): ${err}`);
    }

    // Try 2: ScrapingBee with JS rendering.
    const apiKey = Deno.env.get("SCRAPINGBEE_API_KEY");
    if (!apiKey) {
      errors.push(`${url} (scrapingbee): no API key configured`);
      continue;
    }
    try {
      const sbUrl = `https://app.scrapingbee.com/api/v1/?api_key=${apiKey}&url=${encodeURIComponent(url)}&render_js=true&wait=5000`;
      const res = await fetch(sbUrl);
      if (res.ok) {
        const html = await res.text();
        if (looksLikeRealPage(html)) {
          console.log(`ScrapingBee succeeded: ${url}`);
          return { url, html, via: "scrapingbee" };
        }
        errors.push(`${url} (scrapingbee): empty/shell after JS render`);
      } else {
        errors.push(`${url} (scrapingbee): ${res.status}`);
      }
    } catch (err) {
      errors.push(`${url} (scrapingbee): ${err}`);
    }
  }

  throw new Error(`All sources failed: ${errors.join(" | ")}`);
}

function looksLikeRealPage(html: string): boolean {
  const lower = html.toLowerCase();
  if (lower.includes("just a moment") || lower.includes("attention required")) return false;
  if (lower.includes("unlock more content") || lower.includes("view a short ad")) return false; // paywall
  if (!lower.includes("roatan") && !lower.includes("roatán")) return false;
  if (html.length < 5000) return false;

  // Rendered schedule markup is the strongest signal — but require the
  // class attribute form: the bare strings also appear inside the page's
  // CSS on the UNRENDERED shell (the schedule is injected client-side).
  if (html.includes('class="cruise-day-block') || html.includes('class="ship-row')) return true;

  // Fallback: must mention multiple cruise ships we recognize — otherwise
  // it's a generic 'about this port' page without a schedule.
  let shipMentions = 0;
  for (const ship of Object.keys(SHIP_CAPACITY)) {
    if (html.includes(ship)) {
      shipMentions++;
      if (shipMentions >= 3) return true;
    }
  }
  return false;
}

// --- Parsing ----------------------------------------------------------------
// Tuned to theroatandirectory.com's format as of Aug 2026 (day-block markup;
// only present when the page was rendered with JavaScript, e.g. via
// ScrapingBee). The pre-Aug-2026 format is kept in parseLegacySchedule.

function parseSchedule(html: string): CruiseArrival[] {
  const primary = parseDayBlocks(html);
  if (primary.length > 0) return primary;
  console.log("Day-block parse found nothing; trying legacy format");
  return parseLegacySchedule(html);
}

function parseDayBlocks(html: string): CruiseArrival[] {
  // Restrict to the cruise section — deals and events reuse the same
  // list-title/muted markup and must not leak into the schedule.
  let scope = html;
  const boxStart = html.indexOf('id="cruiseBox"');
  if (boxStart >= 0) {
    const boxEnd = html.indexOf("</section>", boxStart);
    scope = html.substring(boxStart, boxEnd > 0 ? boxEnd : html.length);
  }

  const arrivals: CruiseArrival[] = [];
  const blocks = scope.split(/class="cruise-day-block[^"]*"/).slice(1);
  for (const block of blocks) {
    const headMatch = block.match(/class="cruise-day-head[^"]*"[^>]*>([\s\S]*?)<\/div>/);
    if (!headMatch) continue;

    let isoDate: string | null = null;
    if (/In Port Today/i.test(headMatch[1])) {
      isoDate = todayISO();
    } else {
      // Bilingual header — the English span matches, the Spanish one can't
      // ("Jueves" doesn't end in "day").
      const dm = headMatch[1].match(/([A-Z][a-z]+day),?\s+([A-Za-z]+)\.?\s+(\d{1,2})/);
      if (dm) isoDate = monthDayToIso(dm[2], parseInt(dm[3], 10));
    }
    if (!isoDate) continue;

    const shipRe = /<div\s+class="list-title">\s*([^<]+?)\s*<\/div>\s*<div\s+class="muted">\s*([^<]+?)\s*<\/div>/g;
    let m: RegExpExecArray | null;
    while ((m = shipRe.exec(block)) !== null) {
      const arrival = parseShipFields(m[1], m[2], isoDate);
      if (arrival) arrivals.push(arrival);
    }
  }
  return dedupeAndSort(arrivals);
}

function parseLegacySchedule(html: string): CruiseArrival[] {
  const arrivals: CruiseArrival[] = [];

  // ---- Today's ships (from cruise-today section) -------------------------
  const todayMatch = html.match(/class="cruise-today"[\s\S]*?<\/div>\s*<\/div>\s*<\/div>(?=\s*<div\s+class="list-title">[A-Z][a-z]+day,)/);
  const todaySection = todayMatch ? todayMatch[0] : extractCruiseTodaySection(html);
  if (todaySection) {
    for (const row of extractShipRows(todaySection)) {
      const arrival = parseShipRow(row, todayISO());
      if (arrival) arrivals.push(arrival);
    }
  }

  // ---- Future days (one date header per day, ship-rows follow) -----------
  const dateHeaderRe = /<div\s+class="list-title">\s*([A-Z][a-z]+day),?\s+([A-Z][a-z]+)\s+(\d{1,2})/g;
  const dateHeaders: { isoDate: string; afterIndex: number }[] = [];
  let dm: RegExpExecArray | null;
  while ((dm = dateHeaderRe.exec(html)) !== null) {
    const iso = monthDayToIso(dm[2], parseInt(dm[3], 10));
    if (iso) dateHeaders.push({ isoDate: iso, afterIndex: dm.index + dm[0].length });
  }

  for (let i = 0; i < dateHeaders.length; i++) {
    const start = dateHeaders[i].afterIndex;
    const end = i + 1 < dateHeaders.length ? dateHeaders[i + 1].afterIndex - 200 : Math.min(html.length, start + 8000);
    const section = html.substring(start, end);
    for (const row of extractShipRows(section)) {
      const arrival = parseShipRow(row, dateHeaders[i].isoDate);
      if (arrival) arrivals.push(arrival);
    }
  }

  return dedupeAndSort(arrivals);
}

function dedupeAndSort(arrivals: CruiseArrival[]): CruiseArrival[] {
  const seen = new Set<string>();
  const deduped = arrivals.filter((a) => {
    if (seen.has(a.id)) return false;
    seen.add(a.id);
    return true;
  });
  deduped.sort((a, b) => a.date.localeCompare(b.date) || a.arrivalTime.localeCompare(b.arrivalTime));
  return deduped;
}

/// Fallback when the lookahead-based regex misses (e.g. only one day on page).
function extractCruiseTodaySection(html: string): string | null {
  const startIdx = html.indexOf('class="cruise-today"');
  if (startIdx < 0) return null;
  // Find the next date-header which marks the end of today's block.
  const tail = html.substring(startIdx);
  const nextDateMatch = tail.match(/<div\s+class="list-title">[A-Z][a-z]+day,/);
  const endIdx = nextDateMatch ? nextDateMatch.index! : Math.min(tail.length, 4000);
  return tail.substring(0, endIdx);
}

function extractShipRows(html: string): string[] {
  const rows: string[] = [];
  const re = /class="ship-row[^"]*"[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(html)) !== null) {
    rows.push(m[0]);
  }
  return rows;
}

function parseShipRow(rowHtml: string, isoDate: string): CruiseArrival | null {
  const titleMatch = rowHtml.match(/<div\s+class="list-title">\s*([^<]+?)\s*<\/div>/);
  const mutedMatch = rowHtml.match(/<div\s+class="muted">\s*([^<]+?)\s*<\/div>/);
  if (!titleMatch || !mutedMatch) return null;
  return parseShipFields(titleMatch[1], mutedMatch[1], isoDate);
}

function parseShipFields(rawName: string, rawMuted: string, isoDate: string): CruiseArrival | null {
  const shipName = rawName.trim();
  const muted = rawMuted.trim();

  // Muted format: "Royal Caribbean · 7:00–16:00 · 7600 pax"
  // Split on the bullet character (U+00B7) — also tolerate any whitespace.
  const parts = muted.split(/\s*[·•]\s*/).map((s) => s.trim()).filter(Boolean);
  if (parts.length < 3) return null;

  const cruiseLine = parts[0];

  // Times. The hyphen between times can be en-dash (–), em-dash (—), or hyphen (-).
  const timeMatch = parts[1].match(/(\d{1,2}):(\d{2})\s*[–—\-]\s*(\d{1,2}):(\d{2})/);
  if (!timeMatch) return null;
  const arrivalTime = `${timeMatch[1].padStart(2, "0")}:${timeMatch[2]}`;
  const departureTime = `${timeMatch[3].padStart(2, "0")}:${timeMatch[4]}`;

  // Passenger count.
  const paxMatch = parts[2].match(/(\d[\d,]*)\s*pax/i);
  if (!paxMatch) return null;
  const passengerCount = parseInt(paxMatch[1].replace(/,/g, ""), 10);

  // Port. Carnival ships always dock at Mahogany Bay (their private port);
  // everyone else at Port of Roatán (Coxen Hole).
  const port = /carnival/i.test(cruiseLine) ? "Mahogany Bay" : "Port of Roatán";

  return {
    id: `${isoDate}-${slug(shipName)}-${slug(port)}`,
    shipName,
    cruiseLine,
    port,
    date: isoDate,
    arrivalTime,
    departureTime,
    passengerCount,
  };
}

const MONTH_MAP: Record<string, string> = {
  jan: "01", feb: "02", mar: "03", apr: "04", may: "05", jun: "06",
  jul: "07", aug: "08", sep: "09", oct: "10", nov: "11", dec: "12",
};

/// Converts "May 25" (or just month name + day) into an ISO date. Years are
/// inferred: month >= current month → this year, otherwise → next year.
function monthDayToIso(monthName: string, day: number): string | null {
  const month = MONTH_MAP[monthName.slice(0, 3).toLowerCase()];
  if (!month) return null;
  const now = new Date();
  const currentMonth = now.getMonth() + 1;
  const currentYear = now.getFullYear();
  const monthNum = parseInt(month, 10);
  const year = monthNum >= currentMonth ? currentYear : currentYear + 1;
  return `${year}-${month}-${String(day).padStart(2, "0")}`;
}

function todayISO(): string {
  // Roatán is CST (UTC-6). Use en-CA formatter to get YYYY-MM-DD.
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Tegucigalpa",
    year: "numeric", month: "2-digit", day: "2-digit",
  }).format(new Date());
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

// --- Upload -----------------------------------------------------------------

async function uploadDebug(html: string): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return;
  const supabase = createClient(supabaseUrl, serviceKey);
  const { error } = await supabase.storage
    .from("app-data")
    .upload("cruise_arrivals_debug.html", new Blob([html], { type: "text/html" }), {
      upsert: true,
      cacheControl: "60",
      contentType: "text/html",
    });
  if (error) throw new Error(error.message);
  console.log("Debug HTML uploaded to app-data/cruise_arrivals_debug.html");
}

async function uploadJson(arrivals: CruiseArrival[]): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    throw new Error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing");
  }
  const supabase = createClient(supabaseUrl, serviceKey);

  const json = JSON.stringify(arrivals, null, 2);
  const { error } = await supabase.storage
    .from("app-data")
    .upload("cruise_arrivals.json", new Blob([json], { type: "application/json" }), {
      upsert: true,
      cacheControl: "300",
      contentType: "application/json",
    });

  if (error) throw new Error(`Upload failed: ${error.message}`);
}

// --- Status ------------------------------------------------------------------
// cruise_status.json makes pipeline health observable without log access:
// anyone (or any scheduled checker) can read the public file and see when
// the scrape last succeeded.

async function writeStatus(ok: boolean, detail: Record<string, unknown>): Promise<void> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) return;
  try {
    const supabase = createClient(supabaseUrl, serviceKey);
    const body = JSON.stringify({ ok, lastRun: new Date().toISOString(), ...detail }, null, 2);
    await supabase.storage
      .from("app-data")
      .upload("cruise_status.json", new Blob([body], { type: "application/json" }), {
        upsert: true,
        cacheControl: "60",
        contentType: "application/json",
      });
  } catch (err) {
    console.error(`Failed to write cruise_status.json: ${err}`);
  }
}

// --- Handler ----------------------------------------------------------------

Deno.serve(async (_req) => {
  try {
    // Primary: Keith's Google Sheet (structured, no HTML parsing).
    let arrivals: CruiseArrival[] = [];
    let source = SHEET_LABEL;
    let via = "gviz";
    try {
      arrivals = await fetchSheetArrivals();
      if (arrivals.length > 0) console.log(`Sheet fetch succeeded: ${arrivals.length} arrivals`);
    } catch (err) {
      console.error(`Sheet fetch failed, falling back to HTML scrape: ${err}`);
    }

    // Fallback: rendered-HTML scrape of the public schedule pages.
    if (arrivals.length === 0) {
      const result = await fetchPage();
      arrivals = parseSchedule(result.html);
      source = result.url;
      via = result.via;

      if (arrivals.length === 0) {
        console.error(`Zero arrivals parsed from ${result.url} (via ${result.via}), HTML length: ${result.html.length}`);
        try { await uploadDebug(result.html); } catch (uploadErr) {
          console.error(`Failed to upload debug HTML: ${uploadErr}`);
        }
        await writeStatus(false, {
          source: result.url,
          error: `Sheet and HTML paths both yielded zero arrivals. Debug HTML uploaded. length=${result.html.length}`,
        });
        throw new Error(`Parsed zero arrivals from ${result.url}. Debug uploaded. length=${result.html.length}`);
      }
    }

    await uploadJson(arrivals);
    await writeStatus(true, {
      source,
      via,
      count: arrivals.length,
      firstDate: arrivals[0].date,
      lastDate: arrivals[arrivals.length - 1].date,
    });

    return new Response(
      JSON.stringify({
        ok: true,
        source,
        via,
        count: arrivals.length,
        firstDate: arrivals[0].date,
        lastDate: arrivals[arrivals.length - 1].date,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("scrape-cruise-arrivals failed:", err);
    return new Response(
      JSON.stringify({ ok: false, error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
