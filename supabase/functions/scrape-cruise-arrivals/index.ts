// Roatán Insider — Daily cruise arrivals scraper.
//
// Pulls the next ~30 days of cruise ship arrivals to Roatán from
// cruisetimetables.com, normalizes them into the schema the iOS app
// expects, and uploads the JSON to Supabase Storage at
// `app-data/cruise_arrivals.json`.
//
// Strategy:
//   1. Fetch the page directly with browser-like headers.
//   2. If Cloudflare blocks (403) or returns an obvious challenge page,
//      retry via ScrapingBee's free-tier proxy (env: SCRAPINGBEE_API_KEY).
//   3. Parse the HTML for the schedule table.
//   4. Cross-reference each ship name with a baked-in passenger capacity
//      lookup. Carnival ships dock at Mahogany Bay; everyone else at
//      Port of Roatán (Coxen Hole) — accurate heuristic for Roatán.
//   5. Upload result to Supabase Storage with public-read access.
//   6. If parsing yields zero rows, ABORT — never overwrite a good
//      file with empty data.
//
// Trigger: pg_cron, daily at 09:00 UTC (03:00 Roatán local).
//
// Deploy:
//   supabase functions deploy scrape-cruise-arrivals
//   supabase secrets set SCRAPINGBEE_API_KEY=...   (optional, for fallback)
//
// Schedule (run once in Supabase SQL editor):
//   select cron.schedule(
//     'cruise-arrivals-daily',
//     '0 9 * * *',
//     $$ select net.http_post(
//        url := '<your-project>.functions.supabase.co/scrape-cruise-arrivals',
//        headers := jsonb_build_object('Authorization', 'Bearer <your-anon-key>')
//     ) $$
//   );

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
// Published double-occupancy figures from cruise-line spec sheets. Update
// when a ship is retrofitted or a new one enters service on the Roatán route.

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

// --- Fetching ---------------------------------------------------------------

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

  // Must mention multiple cruise ships we recognize — otherwise it's a
  // generic 'about this port' page without a schedule.
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
// Tuned to theroatandirectory.com's format:
//   <div class="cruise-today"> ... contains "In Port Today" ships
//     <div class="ship-row">
//       <div>
//         <div class="list-title">Star of the Seas</div>
//         <div class="muted">Royal Caribbean · 7:00–16:00 · 7600 pax</div>
//       </div>
//     </div>
//     ...more ship-rows for today
//   </div>
//   <div class="list-title">Monday, May 25 / Lunes, 25 may</div>
//     <div class="ship-row">...</div>
//   <div class="list-title">Tuesday, May 26 / Martes, 26 may</div>
//     <div class="ship-row">...</div>

function parseSchedule(html: string): CruiseArrival[] {
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

  // De-dupe and sort.
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
  const re = /class="ship-row"[\s\S]*?<\/div>\s*<\/div>\s*<\/div>/g;
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

  const shipName = titleMatch[1].trim();
  const muted = mutedMatch[1].trim();

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

// --- Handler ----------------------------------------------------------------

Deno.serve(async (_req) => {
  try {
    const result = await fetchPage();
    const arrivals = parseSchedule(result.html);

    if (arrivals.length === 0) {
      const tableCount = (result.html.match(/<table/gi) ?? []).length;
      const trCount = (result.html.match(/<tr/gi) ?? []).length;
      console.error(`Zero arrivals parsed from ${result.url} (via ${result.via})`);
      console.error(`HTML length: ${result.html.length}, <table>: ${tableCount}, <tr>: ${trCount}`);
      try { await uploadDebug(result.html); } catch (uploadErr) {
        console.error(`Failed to upload debug HTML: ${uploadErr}`);
      }
      throw new Error(`Parsed zero arrivals from ${result.url}. Debug uploaded. table=${tableCount} tr=${trCount} length=${result.html.length}`);
    }

    await uploadJson(arrivals);

    return new Response(
      JSON.stringify({
        ok: true,
        source: result.url,
        via: result.via,
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
