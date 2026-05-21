# scrape-cruise-arrivals

Daily scraper that pulls upcoming cruise arrivals to Roatán from
[cruisetimetables.com](https://www.cruisetimetables.com/cruises-from-roatan-honduras.html),
normalizes them into the iOS app's `CruiseArrival` schema, and uploads the JSON
to Supabase Storage at `app-data/cruise_arrivals.json`.

The iOS app fetches this file on launch (and at most every 6 hours) via
`RemoteDataService.fetchLatest`.

## One-time setup

You need the [Supabase CLI](https://supabase.com/docs/guides/cli) installed and
logged into your project.

### 1. Set the ScrapingBee fallback key as a Supabase secret

```bash
supabase secrets set SCRAPINGBEE_API_KEY=<your-key>
```

This is used **only** if the direct fetch to cruisetimetables.com is blocked by
Cloudflare. ScrapingBee's free tier (1,000 requests/month) covers a daily scrape
with ~970 retry headroom.

If you want to test without ScrapingBee at all, skip this step — the function
will just fail noisily when blocked, which is fine for the first deploy.

### 2. Deploy the function

```bash
supabase functions deploy scrape-cruise-arrivals
```

### 3. Test once manually

```bash
curl -X POST \
  "https://<your-project-ref>.functions.supabase.co/scrape-cruise-arrivals" \
  -H "Authorization: Bearer $(supabase status --output json | jq -r '.[\"ANON_KEY\"]')"
```

Expected response:

```json
{ "ok": true, "count": 27, "firstDate": "2026-05-21", "lastDate": "2026-06-19" }
```

If you get `ok: false`, check the function logs in the Supabase Dashboard
(Edge Functions → scrape-cruise-arrivals → Logs).

### 4. Schedule it daily

In the Supabase SQL Editor:

```sql
-- Enable pg_cron and pg_net if you haven't already
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Schedule the scrape at 09:00 UTC every day (03:00 Roatán local)
select cron.schedule(
  'cruise-arrivals-daily',
  '0 9 * * *',
  $$
  select net.http_post(
    url := 'https://<your-project-ref>.functions.supabase.co/scrape-cruise-arrivals',
    headers := jsonb_build_object(
      'Authorization', 'Bearer <your-anon-key>',
      'Content-Type', 'application/json'
    )
  );
  $$
);
```

Replace `<your-project-ref>` and `<your-anon-key>` with your real values
(visible in Supabase Dashboard → Settings → API).

To remove the schedule later: `select cron.unschedule('cruise-arrivals-daily');`

## How it works

1. Tries to fetch `cruisetimetables.com` directly with browser-like headers.
2. If the response looks like a Cloudflare challenge (HTTP 403, "Just a moment"
   in the body, etc.), retries via ScrapingBee's residential proxy.
3. Parses the HTML schedule table with `deno_dom`. Each row must contain a
   recognizable date and a ship name that matches our `SHIP_CAPACITY` lookup.
4. Assigns the port based on the cruise line — Carnival ships always dock at
   Mahogany Bay (their private port), everyone else docks at Port of Roatán
   (Coxen Hole). This is the standard pattern for Roatán.
5. Passenger count comes from the baked-in `SHIP_CAPACITY` table (published
   double-occupancy figures). Update the table when a ship is retrofitted or
   a new one enters service on the Roatán route.
6. If parsing yields **zero** arrivals, the function aborts without
   overwriting the existing `cruise_arrivals.json` — protects against partial
   scrapes silently nuking the live data.

## When it breaks

The site's HTML changes maybe twice a year. Symptoms:

- Function returns `{ ok: false, error: "Parsed zero arrivals..." }`
- Logs show the page was fetched but no rows matched

Fix: inspect the new HTML structure, update `parseSchedule()` in `index.ts`,
redeploy. Usually a 15-minute job.

## Where the data ends up

- Supabase Storage: `app-data/cruise_arrivals.json` (public read)
- iOS app pulls it via `RemoteDataService.fetchLatest("cruise_arrivals.json", ...)`
  on launch, refreshing at most every 6 hours
- Bundled `events.json` in the app is the offline fallback for first launch
  before the network call completes
