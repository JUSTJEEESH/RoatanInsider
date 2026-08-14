import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

// Publishes editorial data files into the `app-data` bucket.
//
// The content pipeline had no publish step. JSON was generated locally and
// uploaded to Storage by hand, so `public.categories` and the file the app
// actually reads were free to drift apart — and had: the table said one
// thing, the bucket copy said another, and the bundled fallback said a third.
//
// Deliberately takes NO input. `categories.json` is rendered from the
// database; everything else is pulled from a pinned commit in the public
// repo. So invoking this can only ever republish known-good content, which
// is what makes it safe to expose — the worst a stranger with the anon key
// can do is rewrite the bucket with exactly what is already meant to be
// there. Change what gets published by editing SOURCE_COMMIT, not by
// posting a payload.
//
// Idempotent. Every file is compared against the copy already in the bucket
// and written only if it differs, and a manifest version is bumped only for
// a file that actually changed — a bump with no change is wasted bandwidth
// on someone's hotel wifi.

const BUCKET = "app-data";
const REPO = "JUSTJEEESH/RoatanInsider";
const SOURCE_COMMIT = "c59e20bf268e0737d67e9f16ae26191597bedd9d";

// Repo path -> object name in the bucket.
const FROM_REPO: Record<string, string> = {
  "RoatanInsider/Data/dive_sites.json": "dive_sites.json",
  "RoatanInsider/Data/taxi_fares.json": "taxi_fares.json",
};

// Which manifest key gates which file. A file absent from this map is
// fetched by the app on an age timer instead and needs no manifest entry.
const MANIFEST_KEYS: Record<string, string> = {
  "categories.json": "categories",
};

// Read-only diagnostic. Returns the lines of these live bucket objects that
// mention a fare, so a copy in the repo can be checked against the copy
// people are actually reading. Needed because several of these files are
// LARGER in the bucket than in the repo — the repo is behind, and publishing
// it would silently delete live content. Everything listed here is in a
// public bucket already, so this exposes nothing new.
const INSPECT: string[] = ["areas.json", "ask-a-local.json"];
const INSPECT_PATTERN = /taxi/i;

// A floor for manifest versions, for when a file was published out-of-band
// and there is no way to tell afterwards whether the version was raised with
// it or merely rewritten at the same number. A phone only re-fetches when the
// manifest beats what it has cached, so an un-raised version means the new
// file sits in the bucket and nobody ever sees it. Raising a floor costs one
// small re-download per device and is always safe; leaving a stale version in
// place is silently wrong.
const MIN_VERSIONS: Record<string, number> = {
  categories: 80,
};

function client() {
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) throw new Error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing");
  return createClient(url, key);
}

type SB = ReturnType<typeof client>;

async function currentBody(sb: SB, path: string): Promise<string | null> {
  const { data, error } = await sb.storage.from(BUCKET).download(path);
  if (error || !data) return null;
  return await data.text();
}

async function put(sb: SB, path: string, body: string) {
  const { error } = await sb.storage
    .from(BUCKET)
    .upload(path, new Blob([body], { type: "application/json" }), {
      contentType: "application/json",
      upsert: true,
    });
  if (error) throw new Error(`upload ${path}: ${error.message}`);
}

Deno.serve(async () => {
  try {
    const sb = client();
    const payloads: Record<string, string> = {};

    // categories.json comes from the table, so the database stays the single
    // source of truth. Formatting matches the copy already in the bucket
    // byte for byte, so an unchanged table produces an identical file.
    const { data: rows, error } = await sb
      .from("categories")
      .select("id, display_name, icon_name, sort_order")
      .order("sort_order");
    if (error) throw new Error(`read categories: ${error.message}`);
    if (!rows?.length) throw new Error("categories table empty - refusing to publish");
    payloads["categories.json"] = JSON.stringify(
      rows.map((r) => ({
        id: r.id,
        displayName: r.display_name,
        iconName: r.icon_name,
        sortOrder: r.sort_order,
      })),
      null,
      2,
    );

    for (const [repoPath, object] of Object.entries(FROM_REPO)) {
      const res = await fetch(
        `https://raw.githubusercontent.com/${REPO}/${SOURCE_COMMIT}/${repoPath}`,
      );
      if (!res.ok) throw new Error(`fetch ${repoPath}: HTTP ${res.status}`);
      const text = await res.text();
      // Parse before publishing. Shipping a file the app cannot decode is
      // worse than shipping nothing, because the bundled fallback is only
      // consulted when there is no cached copy at all.
      payloads[object] = JSON.stringify(JSON.parse(text), null, 2);
    }

    const written: string[] = [];
    const unchanged: string[] = [];
    for (const [path, body] of Object.entries(payloads)) {
      if ((await currentBody(sb, path)) === body) {
        unchanged.push(path);
        continue;
      }
      await put(sb, path, body);
      written.push(path);
    }

    const bump = written.map((f) => MANIFEST_KEYS[f]).filter(Boolean);
    let manifest: Record<string, unknown> = {};
    const raw = await currentBody(sb, "manifest.json");
    if (raw) {
      try {
        manifest = JSON.parse(raw);
      } catch {
        throw new Error("manifest.json in the bucket is not valid JSON - refusing to overwrite it");
      }
    }
    const inspected: Record<string, unknown> = {};
    for (const name of INSPECT) {
      const body = await currentBody(sb, name);
      if (body === null) { inspected[name] = "not in bucket"; continue; }
      inspected[name] = {
        bytes: new TextEncoder().encode(body).length,
        matches: body.split("\n").map((l) => l.trim()).filter((l) => INSPECT_PATTERN.test(l)),
      };
    }

    const raised: string[] = [];
    for (const key of new Set([...bump, ...Object.keys(MIN_VERSIONS)])) {
      const entry = (manifest[key] ?? {}) as { version?: number; file?: string };
      const file = Object.keys(MANIFEST_KEYS).find((f) => MANIFEST_KEYS[f] === key)!;
      const next = Math.max(
        bump.includes(key) ? (entry.version ?? 0) + 1 : (entry.version ?? 0),
        MIN_VERSIONS[key] ?? 0,
      );
      if (next === entry.version) continue;
      manifest[key] = { version: next, file: entry.file ?? file };
      raised.push(`${key} -> ${next}`);
    }
    if (raised.length) {
      manifest.updatedAt = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
      await put(sb, "manifest.json", JSON.stringify(manifest, null, 2));
    }

    return new Response(
      JSON.stringify({ ok: true, commit: SOURCE_COMMIT, written, unchanged, raised, inspected, manifest }, null, 2),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
