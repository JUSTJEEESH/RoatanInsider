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
import { DOMParser, type Element } from "https://deno.land/x/deno_dom@v0.1.46/deno-dom-wasm.ts";

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

const SOURCE_URL = "https://www.cruisetimetables.com/cruises-from-roatan-honduras.html";
const BROWSER_HEADERS = {
  "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
  "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
  "Accept-Encoding": "gzip, deflate, br",
  "DNT": "1",
  "Upgrade-Insecure-Requests": "1",
};

async function fetchPage(): Promise<string> {
  // Try 1: direct fetch with browser headers.
  try {
    const res = await fetch(SOURCE_URL, { headers: BROWSER_HEADERS });
    if (res.ok) {
      const html = await res.text();
      if (looksLikeRealPage(html)) return html;
    }
    console.log(`Direct fetch returned ${res.status}; trying ScrapingBee fallback`);
  } catch (err) {
    console.log(`Direct fetch failed: ${err}; trying ScrapingBee fallback`);
  }

  // Try 2: ScrapingBee (residential proxy + Cloudflare bypass).
  const apiKey = Deno.env.get("SCRAPINGBEE_API_KEY");
  if (!apiKey) {
    throw new Error("Direct fetch blocked AND no SCRAPINGBEE_API_KEY configured");
  }
  const sbUrl = `https://app.scrapingbee.com/api/v1/?api_key=${apiKey}&url=${encodeURIComponent(SOURCE_URL)}&render_js=false`;
  const res = await fetch(sbUrl);
  if (!res.ok) {
    throw new Error(`ScrapingBee returned ${res.status}: ${await res.text()}`);
  }
  const html = await res.text();
  if (!looksLikeRealPage(html)) {
    throw new Error("ScrapingBee returned HTML but it doesn't look like the schedule page");
  }
  return html;
}

function looksLikeRealPage(html: string): boolean {
  const lower = html.toLowerCase();
  // Cloudflare challenge / Just-a-moment pages.
  if (lower.includes("just a moment") || lower.includes("attention required")) return false;
  // Should mention Roatán somewhere.
  if (!lower.includes("roatan") && !lower.includes("roatán")) return false;
  return html.length > 1000;
}

// --- Parsing ----------------------------------------------------------------

function parseSchedule(html: string): CruiseArrival[] {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) throw new Error("Failed to parse HTML");

  const arrivals: CruiseArrival[] = [];

  // cruisetimetables.com typically uses table rows. We scan all <tr> elements
  // and look for ones that have:
  //   - a recognisable date (multiple formats)
  //   - a recognisable ship name (matches our capacity lookup)
  const rows = doc.querySelectorAll("tr");
  for (const node of rows) {
    const row = node as Element;
    const cells = Array.from(row.querySelectorAll("td")).map((c) =>
      (c.textContent ?? "").trim()
    );
    if (cells.length < 3) continue;

    const rawDate = findDate(cells);
    if (!rawDate) continue;
    const isoDate = toIsoDate(rawDate);
    if (!isoDate) continue;

    const ship = findShip(cells);
    if (!ship) continue;

    const times = findTimes(cells);
    const lookup = SHIP_CAPACITY[ship];
    const line = lookup?.line ?? null;
    const capacity = lookup?.capacity ?? 0;

    const port = lookup?.line === "Carnival" ? "Mahogany Bay" : "Port of Roatán";

    arrivals.push({
      id: `${isoDate}-${slug(ship)}-${slug(port)}`,
      shipName: ship,
      cruiseLine: line,
      port,
      date: isoDate,
      arrivalTime: times.arrival,
      departureTime: times.departure,
      passengerCount: capacity,
    });
  }

  // De-dupe on id and sort.
  const seen = new Set<string>();
  const deduped = arrivals.filter((a) => {
    if (seen.has(a.id)) return false;
    seen.add(a.id);
    return true;
  });
  deduped.sort((a, b) => a.date.localeCompare(b.date) || a.arrivalTime.localeCompare(b.arrivalTime));
  return deduped;
}

function findDate(cells: string[]): string | null {
  for (const cell of cells) {
    // Match formats like: "Mon, 21 May 2026", "21 May 2026", "2026-05-21", "05/21/2026"
    if (/\b\d{1,2}\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i.test(cell)) return cell;
    if (/\b\d{4}-\d{2}-\d{2}\b/.test(cell)) return cell;
    if (/\b\d{1,2}\/\d{1,2}\/\d{4}\b/.test(cell)) return cell;
  }
  return null;
}

function toIsoDate(raw: string): string | null {
  // ISO already.
  const isoMatch = raw.match(/(\d{4})-(\d{2})-(\d{2})/);
  if (isoMatch) return `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}`;

  // US slash.
  const usMatch = raw.match(/(\d{1,2})\/(\d{1,2})\/(\d{4})/);
  if (usMatch) {
    const m = usMatch[1].padStart(2, "0");
    const d = usMatch[2].padStart(2, "0");
    return `${usMatch[3]}-${m}-${d}`;
  }

  // "21 May 2026" or "Mon, 21 May 2026"
  const monthMap: Record<string, string> = {
    jan: "01", feb: "02", mar: "03", apr: "04", may: "05", jun: "06",
    jul: "07", aug: "08", sep: "09", oct: "10", nov: "11", dec: "12",
  };
  const longMatch = raw.match(/(\d{1,2})\s+([A-Za-z]{3,9})\s+(\d{4})/);
  if (longMatch) {
    const month = monthMap[longMatch[2].slice(0, 3).toLowerCase()];
    if (!month) return null;
    const d = longMatch[1].padStart(2, "0");
    return `${longMatch[3]}-${month}-${d}`;
  }

  return null;
}

function findShip(cells: string[]): string | null {
  // Look for an exact match against the capacity table first.
  for (const cell of cells) {
    if (SHIP_CAPACITY[cell]) return cell;
  }
  // Fallback: try a fuzzy match — sometimes the cell contains extra text.
  for (const cell of cells) {
    for (const known of Object.keys(SHIP_CAPACITY)) {
      if (cell.toLowerCase().includes(known.toLowerCase())) return known;
    }
  }
  return null;
}

function findTimes(cells: string[]): { arrival: string; departure: string } {
  // Look for two HH:mm patterns in the row. First is arrival, second is departure.
  const matches: string[] = [];
  for (const cell of cells) {
    const re = /\b(\d{1,2}):(\d{2})\s*(am|pm)?\b/gi;
    let m: RegExpExecArray | null;
    while ((m = re.exec(cell)) !== null) {
      matches.push(normaliseTime(m[1], m[2], m[3]));
      if (matches.length >= 2) break;
    }
    if (matches.length >= 2) break;
  }
  return {
    arrival: matches[0] ?? "08:00",
    departure: matches[1] ?? "17:00",
  };
}

function normaliseTime(h: string, m: string, ampm?: string): string {
  let hour = parseInt(h, 10);
  const minute = parseInt(m, 10);
  if (ampm) {
    const lower = ampm.toLowerCase();
    if (lower === "pm" && hour < 12) hour += 12;
    if (lower === "am" && hour === 12) hour = 0;
  }
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

// --- Upload -----------------------------------------------------------------

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
    const html = await fetchPage();
    const arrivals = parseSchedule(html);

    if (arrivals.length === 0) {
      // Diagnostic: surface what we actually got so we can debug the parser
      // without redeploying. The HTML snippet shows up in Supabase function logs.
      const snippet = html.slice(0, 4000);
      const tableCount = (html.match(/<table/gi) ?? []).length;
      const trCount = (html.match(/<tr/gi) ?? []).length;
      console.error("Zero arrivals parsed.");
      console.error(`HTML length: ${html.length}, <table> count: ${tableCount}, <tr> count: ${trCount}`);
      console.error(`First 4000 chars of HTML:\n${snippet}`);
      throw new Error(`Parsed zero arrivals — see logs for HTML diagnostic. table=${tableCount} tr=${trCount} length=${html.length}`);
    }

    await uploadJson(arrivals);

    return new Response(
      JSON.stringify({ ok: true, count: arrivals.length, firstDate: arrivals[0].date, lastDate: arrivals[arrivals.length - 1].date }),
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
