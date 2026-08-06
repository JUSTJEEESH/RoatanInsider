# scrape-cruise-arrivals

Twice-daily scraper that pulls upcoming cruise arrivals to Roatán, normalizes
them into the iOS app's `CruiseArrival` schema, and uploads the JSON to
Supabase Storage at `app-data/cruise_arrivals.json`.

The iOS app (`CruiseArrivalsService`) fetches this file on launch, refreshing
at most every 6 hours. If the data ever goes stale (no rows covering today),
the app hides the "Ships in Port Today" card rather than claiming a quiet day.

## Data source (in priority order)

1. **PRIMARY — Keith's Google Sheet.** theroatandirectory.com renders its
   cruise schedule client-side from a public Google Sheet
   (spreadsheet `1Z1XVw4Ya2fhvGZHYk27QXQgxvF1DNJa11i7CLUbvMnc`, tab
   `cruise_schedule`), read via the gviz JSON API:

   ```
   https://docs.google.com/spreadsheets/d/<id>/gviz/tq?tqx=out:json&headers=1&sheet=cruise_schedule
   ```

   Columns: Date, Ship Name, Cruise Line, Arrive, Depart, Passengers, Notes.
   Structured rows, no HTML parsing, and the passenger figures are Keith's
   actual expected counts (better than published capacities). Keith maintains
   it daily; Josh has his explicit permission to use the data.

2. **FALLBACK — rendered-HTML scrape** of theroatandirectory.com and public
   aggregators (direct fetch, then ScrapingBee with `render_js=true` when a
   site is Cloudflare-blocked or client-side rendered; secret:
   `SCRAPINGBEE_API_KEY`). Handles both the Aug-2026 `cruise-day-block`
   markup and the older bare `ship-row` format.

Ports are assigned by cruise line: Carnival ships dock at Mahogany Bay
(their private port); everyone else at Port of Roatán (Coxen Hole).

## Safety rails

- If BOTH paths yield zero arrivals, the run ABORTS without overwriting the
  existing `cruise_arrivals.json`, and uploads the fetched page to
  `app-data/cruise_arrivals_debug.html` for inspection.
- Every run (success or failure) writes `app-data/cruise_status.json`:
  `{ ok, lastRun, source, via, count, firstDate, lastDate }` — check this
  file first when debugging. It's public:
  `https://<project-ref>.supabase.co/storage/v1/object/public/app-data/cruise_status.json`

## Schedule

pg_cron job `cruise-arrivals-daily`, `30 11,23 * * *` (11:30 + 23:30 UTC =
05:30 + 17:30 island time). Two runs a day so a transient failure self-heals
the same day.

The season schedule barely moves, so twice daily is plenty — but the timing
matters. 05:30 island lands before the first ships dock; 17:30 picks up any
correction made during the working day, rather than parking it until 3am as
the old `0 9,15` slots did.

## History / when it breaks

- **June–Aug 2026 outage:** the site moved its schedule rendering client-side
  and changed `class="ship-row"` to `class="ship-row ship-shade-N"`, so the
  HTML parser matched nothing and the abort rail (correctly) refused to
  overwrite — but data went stale for 7 weeks with nothing surfacing it.
  That's why the sheet is now primary, why `cruise_status.json` exists, and
  why the app hides the card on stale data.
- **Sheet columns renamed/moved:** `fetchSheetArrivals` matches columns by
  label substring (date/ship/line/arrive/depart/passenger/note) and throws if
  date or ship is missing — falls back to HTML scrape, and status shows the
  failure. Update the matching, redeploy.
