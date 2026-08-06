# publish-app-data

Publishes editorial data files into the `app-data` bucket, and raises the
manifest versions that make phones go and fetch them.

## Why it exists

There was no publish step. `import_all.py` generated JSON locally and then
printed "upload these files to Supabase" — a manual step that is easy to do
halfway. That is exactly what happened to the categories: `public.categories`
in Postgres said one thing, the copy in the bucket said another, and the
bundled fallback in the app said a third, with a different ordering to boot.

## What it publishes

| Object | Source | How the app picks it up |
|---|---|---|
| `categories.json` | rendered from `public.categories` | manifest version |
| `dive_sites.json` | pinned commit in the repo | 24h age timer |
| `taxi_fares.json` | pinned commit in the repo | 24h age timer |

## How to run it

```sql
select net.http_post(
  url := 'https://vbxmmslzanixvqswtnnv.functions.supabase.co/publish-app-data',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer <anon key>'
  ),
  timeout_milliseconds := 60000
);
```

Then read the reply — `net.http_post` is asynchronous and the response lands
in a table:

```sql
select status_code, content from net._http_response order by id desc limit 1;
```

It reports which files it wrote, which were already current, and which
manifest versions it raised.

## Design notes

**It takes no input.** Every payload is either rendered from the database or
pulled from a commit pinned in the source. That is what makes it safe to
leave exposed: the worst a stranger with the anon key can do is rewrite the
bucket with exactly what is supposed to be there. To publish something
different, change `SOURCE_COMMIT` and redeploy — don't add a request body.

**It is idempotent.** Files are compared against the copy in the bucket and
written only when they differ; manifest versions are raised only for files
that actually changed. Running it twice is a no-op, not a version ratchet
that makes every phone re-download.

**It parses before it publishes.** A file the app can't decode is worse than
no file at all, because the bundled fallback is only consulted when there is
no cached copy — a bad remote copy poisons the cache and there is no way back
without a release.

**`MIN_VERSIONS` is a floor**, for when a file was published by hand and
there's no way to tell afterwards whether the version was raised with it or
just rewritten at the same number. A phone re-fetches only when the manifest
beats what it has cached, so an un-raised version means the new file sits in
the bucket and nobody ever sees it. Raising the floor costs one small
re-download per device and is always safe.

## Changing categories

Edit `public.categories`, then run the function. Don't edit the bucket file
directly — the function renders it from the table and will overwrite you.
Keep `RoatanInsider/Data/categories.json` in step as the offline fallback.
