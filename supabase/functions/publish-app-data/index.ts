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
const SOURCE_COMMIT = "06ed8f8b471d626d2838e342960d23666ceea037";

// Repo path -> object name in the bucket.
const FROM_REPO: Record<string, string> = {
  "RoatanInsider/Data/dive_sites.json": "dive_sites.json",
  "RoatanInsider/Data/taxi_fares.json": "taxi_fares.json",
};

// Which manifest key gates which file. A file absent from this map is
// fetched by the app on an age timer instead and needs no manifest entry.
const MANIFEST_KEYS: Record<string, string> = {
  "categories.json": "categories",
  "areas.json": "areas",
  "ask-a-local.json": "askALocal",
  "businesses.json": "businesses",
  "cruise-coxen-hole.json": "cruiseCoxenHole",
  "cruise-mahogany-bay.json": "cruiseMahoganyBay",
};

// Read-only diagnostic. Returns the lines of these live bucket objects that
// mention a fare, so a copy in the repo can be checked against the copy
// people are actually reading. Everything listed is in a public bucket
// already, so this exposes nothing new.
const INSPECT: string[] = ["areas.json", "ask-a-local.json"];
const INSPECT_PATTERN = /taxi/i;

// Surgical edits to files that live ONLY in the bucket.
//
// areas.json, ask-a-local.json, essentials.json and the cruise guides are
// all bigger in the bucket than in this repo — the bucket copy is the newer
// one, carrying edits the repo never received. Republishing the repo version
// would delete them. So these files are patched in place instead: read the
// live copy, swap one exact string, write it back, and leave every other
// byte alone.
//
// PATCHES ARE APPLIED IN ORDER AND THEY COMPOUND. A patch that rewrites a
// sentence sitting inside another patch's `replace` text leaves that second
// patch unable to recognise its own output as already-applied — which is
// exactly what happened to the taxi answer here, and the run aborted rather
// than writing the file half-done. Every `replace` must describe the file as
// it should look AFTER all earlier patches have run.
//
// A patch whose `find` does not appear EXACTLY ONCE is abandoned and the
// file is left untouched, because a find that matched zero times means the
// text already changed under us, and one that matched twice means we do not
// understand the file well enough to be editing it.
const PATCHES: { file: string; find: string; replace: string }[] = [
  {
    file: "areas.json",
    find: "take a water taxi ($3/person, 5 minutes)",
    replace: "take a water taxi ($5/person with three aboard, $10 each if fewer, 5 minutes)",
  },
  {
    file: "ask-a-local.json",
    find: "If you pay for a $3 water taxi with a $20, you might not get change.",
    replace: "If you pay for a $5 water taxi with a $20, you might not get change.",
  },
  {
    file: "ask-a-local.json",
    find: "Water taxis between West End and West Bay are $3 per person and run constantly through the day.",
    replace: "The water taxi between West End and West Bay is $5 a head once there are three of you in the boat, $10 each if it's one or two, and it runs all day.",
  },
  {
    file: "cruise-coxen-hole.json",
    find: "Take a water taxi from West Bay to West End ($3 per person, 5 minutes)",
    replace: "Take a water taxi from West Bay to West End ($5 per person with three aboard, $10 if fewer, 5 minutes)",
  },
  {
    file: "cruise-mahogany-bay.json",
    find: "$3 for water taxi, free to walk",
    replace: "$5-10 per person for the water taxi, free to walk",
  },
  {
    file: "businesses.json",
    find: "a scenic 10-minute ride through the lagoon for about $3. The fun, fast alternative to the road. Minimum 3 passengers per trip.",
    replace: "a scenic 10-minute ride through the lagoon. $5 a head once three of you are aboard, $10 each if it's one or two. The fun, fast alternative to the road.",
  },
  {
    file: "businesses.json",
    find: "Only $3-5 per person and way more fun than driving.",
    replace: "Way more fun than driving, and if the drivers are slow or already heading over they'll often do a deal.",
  },
  {
    file: "areas.json",
    find: "From the Port of Roat\u00e1n: 20-minute taxi ($8-12/person)",
    replace: "From the Port of Roat\u00e1n: 20-minute taxi ($10-15/person)",
  },
  {
    file: "ask-a-local.json",
    find:
      "There are no meters. Always agree on the price before you get in. Typical fares: West Bay to West End is $5, Mahogany Bay port to West Bay is $5-8 per person, Coxen Hole to West End is $10-15. Shared colectivo minibuses run the main road for about $1-2 per person \u2014 they're totally fine to use. Water taxis between West End and West Bay are $3 per person and run constantly during the day. Ask your hotel or a restaurant to call you a taxi \u2014 they'll get you a fair price.",
    replace:
      "There are no meters, so agree the price before you get in \u2014 every time, even for a run you did yesterday. Leaving the airport is the one exception: those rates are posted at the terminal and fixed for the whole car, up to four people, 6am to 6pm. It's $10 to Coxen Hole, $30 to West End, $35 to West Bay. After 6pm, or anywhere else on the island, you're negotiating again. Ask for a colectivo if you don't mind the stops \u2014 that's a shared seat priced per person, about 45-50 lempiras along the main road, and being quoted the whole-car price for one is how visitors overpay here. The water taxi between West End and West Bay is $5 a head once there are three of you in the boat, $10 each if it's one or two, and it runs all day. The full fare table is under Tools if you want to check a particular run.",
  },
];

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

    // Patched files join the same compare-and-write path below, so an
    // already-correct bucket copy still counts as unchanged.
    const patchSkipped: string[] = [];
    for (const file of new Set(PATCHES.map((p) => p.file))) {
      const live = await currentBody(sb, file);
      if (live === null) { patchSkipped.push(`${file}: not in bucket`); continue; }
      let next = live;
      let abort: string | null = null;
      for (const patch of PATCHES.filter((p) => p.file === file)) {
        const hits = next.split(patch.find).length - 1;
        if (hits === 1) { next = next.split(patch.find).join(patch.replace); continue; }
        // Already applied is not a failure; anything else is.
        if (hits === 0 && next.includes(patch.replace)) continue;
        abort = `${file}: "${patch.find.slice(0, 40)}..." matched ${hits} times`;
        break;
      }
      if (abort) { patchSkipped.push(abort); continue; }
      try {
        JSON.parse(next);
      } catch {
        patchSkipped.push(`${file}: patched result is not valid JSON`);
        continue;
      }
      payloads[file] = next;
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
      JSON.stringify({ ok: true, commit: SOURCE_COMMIT, written, unchanged, raised, patchSkipped, inspected, manifest }, null, 2),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ ok: false, error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
