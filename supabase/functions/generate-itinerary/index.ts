// Roatán Insider — Claude-backed itinerary generator.
//
// Source of truth for the deployed Supabase Edge Function `generate-itinerary`
// in project vbxmmslzanixvqswtnnv. Redeploy via the Supabase MCP or the
// `supabase functions deploy generate-itinerary` CLI command.
//
// Takes a ranked candidate pool + day/interest context from the iOS client,
// asks Claude Sonnet 4.6 to compose a day-by-day schedule, and returns it
// plus a short rationale to show the user. Costs are kept low via prompt
// caching on the frozen system prompt — the cache hits on every call after
// the first within a 5-minute window.
//
// Auth: the iOS app sends the Supabase anon key in the `apikey` header.
// verify_jwt is off (matches sync-app-data + resolve-gmaps). If this ever
// becomes a budget concern, flip verify_jwt on or rate-limit by deviceId.
//
// Secrets required (set via Supabase dashboard → Edge Functions → Secrets):
//   ANTHROPIC_API_KEY   — your Anthropic API key (sk-ant-...).

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const MODEL = "claude-sonnet-4-6";
const ANTHROPIC_VERSION = "2023-06-01";
const MAX_CANDIDATES = 80;
const MAX_DAYS = 14;

// JSON schema enforced via output_config.format. We model `schedule` as an
// ARRAY of {dateKey, businessIds} objects, not a dict keyed by date, because
// Anthropic's strict mode rejects `additionalProperties` as a schema (only
// `false` is allowed). The function converts back to a dict before responding
// so the iOS client sees the same {dateKey: [businessId]} shape it expects.
const ITINERARY_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    schedule: {
      type: "array",
      description:
        "One entry per day, in the same order as the input 'days' array.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          dateKey: {
            type: "string",
            description: "yyyy-MM-dd; must match a dateKey from the input.",
          },
          businessIds: {
            type: "array",
            description: "Ordered list of business IDs for this day.",
            items: { type: "string" },
          },
        },
        required: ["dateKey", "businessIds"],
      },
    },
    rationale: {
      type: "string",
      description:
        "Short, friendly 'why this plan' note. 2-3 sentences max, second person.",
    },
  },
  required: ["schedule", "rationale"],
};

// IMPORTANT: this prompt must stay byte-identical across requests for prompt
// caching to hit. No timestamps, no per-request IDs, no UUIDs — anything
// dynamic goes in the user message instead.
const SYSTEM_PROMPT = `You are an expert local travel planner for Roatán, Honduras. You design day-by-day itineraries that feel like advice from a knowledgeable local friend — opinionated, specific, geographically coherent.

RULES:
- Group each day around ONE area when possible (West Bay, West End, Sandy Bay, French Harbour, etc.) so visitors aren't crisscrossing the island. Roatán is 48 miles long and roads are slow — moving between West Bay and Oak Ridge in a single day is a mistake.
- Mix categories per day: aim for one food spot, one activity or beach, and one evening spot (drinks or nightlife) when the day length supports it.
- First day: lighter (2-3 items) — visitors have just arrived. Last day: lighter (2-3 items) — they need time to pack and depart. Middle days: 4-5 items each.
- Cruise-day travelers (single day plans): keep everything close to the cruise port unless the candidate pool clearly supports an excursion. Allow ~2 hours buffer before ship departure.
- Saturday and Sunday: weight toward beaches, casual food, and bars. Avoid services that close on weekends.
- ALWAYS use business IDs from the provided "candidates" list. NEVER invent IDs. NEVER reuse the same business ID across multiple days.
- Favorites (isFavorite: true) and insider picks (isInsiderPick: true) should be prioritized but not forced — only include them if they fit the day's theme and area.
- For interests the user listed, weight those categories more heavily. Ignored interests (no candidate matches) are fine — don't force them in.

FILLING LONG TRIPS:
- Visitors are on the island every day in the "days" array. Every day should have SOMETHING in it — an empty day reads as a bug, not a feature.
- If the candidate pool is small relative to days × itemsPerDay, prefer 2-3 strong items per day across ALL days over 5 perfect items on half the days. Spread the goodness.
- For mid-trip days when the best picks are exhausted, it's fine to revisit an AREA visited earlier in the trip (beaches especially are worth a second day) — just don't repeat the same business ID.
- Only return an empty businessIds array for a day if you've genuinely exhausted geographically and categorically reasonable picks. A 10-day trip with empty days 6-10 is worse than a 10-day trip with simpler picks on days 6-10.

OUTPUT SHAPE:
- The "schedule" field is an ARRAY. One entry per day, in the same order as the input "days" array. Each entry has a "dateKey" (matching the input) and a "businessIds" array (ordered list of business IDs for that day).

RATIONALE FIELD:
- Write in second person ("I put you in West Bay on day 1 because...").
- Warm, confident tone — like a friend who's been to the island many times.
- 2-3 sentences max. The user reads this as a small caption under their itinerary, not a wall of text.
- Reference 1-2 specific picks by name if it makes the reasoning concrete.`;

interface Candidate {
  id: string;
  name: string;
  category: string;
  area: string;
  features?: string[];
  priceRange?: number;
  isFavorite?: boolean;
  isInsiderPick?: boolean;
  rating?: number;
}

interface DayInfo {
  dayNumber: number;
  dateKey: string;
  weekday: string;
}

interface RequestPayload {
  travelerType?: string;
  interests?: string[];
  days: DayInfo[];
  itemsPerDay?: number;
  candidates: Candidate[];
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }
  if (!ANTHROPIC_API_KEY) {
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  let body: RequestPayload;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  if (!Array.isArray(body.candidates) || body.candidates.length === 0) {
    return jsonResponse({ error: "no_candidates" }, 400);
  }
  if (body.candidates.length > MAX_CANDIDATES) {
    return jsonResponse(
      { error: "too_many_candidates", max: MAX_CANDIDATES },
      400,
    );
  }
  if (!Array.isArray(body.days) || body.days.length === 0) {
    return jsonResponse({ error: "no_days" }, 400);
  }
  if (body.days.length > MAX_DAYS) {
    return jsonResponse({ error: "too_many_days", max: MAX_DAYS }, 400);
  }

  const userMessage = JSON.stringify({
    travelerType: body.travelerType ?? "vacationer",
    interests: body.interests ?? [],
    itemsPerDay: body.itemsPerDay ?? 4,
    days: body.days,
    candidates: body.candidates.map((c) => ({
      id: c.id,
      name: c.name,
      category: c.category,
      area: c.area,
      features: (c.features ?? []).slice(0, 6),
      price: c.priceRange ?? 0,
      fav: c.isFavorite ? 1 : 0,
      insider: c.isInsiderPick ? 1 : 0,
      rating: c.rating ?? null,
    })),
  });

  const claudePayload = {
    model: MODEL,
    max_tokens: 4096,
    thinking: { type: "disabled" },
    output_config: {
      effort: "low",
      format: {
        type: "json_schema",
        schema: ITINERARY_SCHEMA,
      },
    },
    system: [
      {
        type: "text",
        text: SYSTEM_PROMPT,
        cache_control: { type: "ephemeral" },
      },
    ],
    messages: [{ role: "user", content: userMessage }],
  };

  let claudeResp: Response;
  try {
    claudeResp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": ANTHROPIC_VERSION,
      },
      body: JSON.stringify(claudePayload),
    });
  } catch (err) {
    return jsonResponse(
      { error: "upstream_unreachable", detail: String(err) },
      502,
    );
  }

  if (!claudeResp.ok) {
    const errText = await claudeResp.text();
    return jsonResponse(
      {
        error: "upstream_failed",
        status: claudeResp.status,
        detail: errText.slice(0, 500),
      },
      502,
    );
  }

  type ClaudeContentBlock = { type: string; text?: string };
  type ClaudeUsage = {
    input_tokens?: number;
    output_tokens?: number;
    cache_creation_input_tokens?: number;
    cache_read_input_tokens?: number;
  };
  type ClaudeResponse = {
    content?: ClaudeContentBlock[];
    usage?: ClaudeUsage;
    stop_reason?: string;
  };

  let claudeData: ClaudeResponse;
  try {
    claudeData = await claudeResp.json() as ClaudeResponse;
  } catch {
    return jsonResponse({ error: "upstream_invalid_json" }, 502);
  }

  if (claudeData.stop_reason === "refusal") {
    return jsonResponse({ error: "refused" }, 502);
  }

  const textBlock = claudeData.content?.find((b) => b.type === "text");
  if (!textBlock?.text) {
    return jsonResponse({ error: "no_text_block" }, 502);
  }

  interface ScheduleEntry {
    dateKey: string;
    businessIds: string[];
  }
  let parsed: { schedule?: ScheduleEntry[]; rationale?: string };
  try {
    parsed = JSON.parse(textBlock.text);
  } catch {
    return jsonResponse(
      { error: "parse_failed", raw: textBlock.text.slice(0, 500) },
      502,
    );
  }

  // Build the day-keyed dict the iOS client expects, and validate every ID
  // came from the candidate pool. Hallucinated or repeated IDs are dropped
  // silently rather than passed through.
  const validIds = new Set(body.candidates.map((c) => c.id));
  const validDateKeys = new Set(body.days.map((d) => d.dateKey));
  const byDate = new Map<string, string[]>();
  for (const entry of parsed.schedule ?? []) {
    if (typeof entry?.dateKey !== "string") continue;
    if (!validDateKeys.has(entry.dateKey)) continue;
    byDate.set(entry.dateKey, entry.businessIds ?? []);
  }

  const cleanedSchedule: Record<string, string[]> = {};
  const seenIds = new Set<string>();
  for (const day of body.days) {
    const ids = byDate.get(day.dateKey) ?? [];
    const filtered: string[] = [];
    for (const id of ids) {
      if (typeof id === "string" && validIds.has(id) && !seenIds.has(id)) {
        filtered.push(id);
        seenIds.add(id);
      }
    }
    cleanedSchedule[day.dateKey] = filtered;
  }

  const usage = claudeData.usage ?? {};
  console.log(JSON.stringify({
    event: "itinerary_generated",
    model: MODEL,
    days: body.days.length,
    candidates: body.candidates.length,
    cache_read: usage.cache_read_input_tokens ?? 0,
    cache_creation: usage.cache_creation_input_tokens ?? 0,
    input: usage.input_tokens ?? 0,
    output: usage.output_tokens ?? 0,
  }));

  return jsonResponse({
    schedule: cleanedSchedule,
    rationale: typeof parsed.rationale === "string" ? parsed.rationale : "",
    model: MODEL,
  });
});

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    },
  });
}

function corsResponse(): Response {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Max-Age": "86400",
    },
  });
}
