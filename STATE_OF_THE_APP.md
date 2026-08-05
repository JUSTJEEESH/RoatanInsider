# Roatán Insider — State of the App

## Update — August 5, 2026

The May redesign branch below was merged to `main` in full (69 commits,
+12k lines) after sitting unmerged since May 21. Everything described in
this document is now on `main`. Changes since:

- **Cruise pipeline fixed and re-architected.** The scraper had been failing
  silently since June 14 (theroatandirectory.com moved its schedule to
  client-side rendering and changed its markup), so the app showed "quiet
  day" while ships were in port. The scraper now reads Keith's public
  Google Sheet (`cruise_schedule` tab) directly via the gviz JSON API —
  structured data, no HTML parsing — with the HTML scrape kept as fallback.
  Runs twice daily (09:00/15:00 UTC). `CruiseArrivalsService.hasCurrentData`
  now gates the Home card: stale data hides the section instead of lying.
- **Music/events pipeline built.** New `scrape-music-events` Edge Function
  pulls the weekly schedule from Blue Wave Radio's Roatán Music Scene
  (Keith's Apps Script JSONP feed — the same data the website renders),
  normalizes it to the `Event` schema, and publishes `events.json` twice
  daily (09:10/15:10 UTC). `EventsService` now refreshes from remote like
  the cruise service. Josh's "Don't Miss" curation is preserved as a
  featured overlay inside the scraper. 72 events live as of today.
- **Pipeline health is observable:** both scrapers write public
  `cruise_status.json` / `music_status.json` to the `app-data` bucket on
  every run, and refuse to overwrite good data with empty parses (debug
  payloads get uploaded instead).
- **Bundled `events.json` and `cruise_arrivals.json` seeds refreshed** to the
  Aug 5 live data (offline/first-launch fallback only).
- The "watch out" items below have moved: TelemetryDeck ✅ live, Sentry ✅
  installed, CloudKit favorites ✅ built, Trending ✅ shipped. Still open:
  offline-map-tiles paywall claim, uncapped Anthropic billing on
  `generate-itinerary`, Spanish UI coverage, east-side content fill.

*Original document (May 20, 2026) follows.*

---

*May 2026. Branch: `claude/roatan-app-redesign-CtjgW`.*

This is an honest snapshot: where the app is, what's shipped recently, what works,
what's half-built, and — most importantly — what would turn this from "a really
good Roatán app" into the one cruise passengers WhatsApp to their friends before
they've left the port.

---

## Executive snapshot

Roatán Insider is **shippable today**. The core experience — browse, search, map,
favorites, currency tools, cruise-day mode, AI-generated itineraries — is built,
polished, and working end-to-end on real infrastructure. 94 verified businesses,
14 areas, multi-port cruise guides, Spanish localization plumbing, App Intents,
Live Activities, widgets, deep linking, App Store-ready privacy manifest.

What it doesn't yet have: a single feature that makes a stranger pull out their
phone in line for a margarita and say *"wait, you have to install this."* That's
the gap this doc is about closing.

---

## What's live

### The six tabs

| Tab | What it does | Polish |
|---|---|---|
| **Home** | Hero, Live Conditions strip (real weather + sunset + UV + reef), Right Now feed, Featured, Collections, Categories, Insider Picks, Quick Guides | ✅ Brand-defining |
| **Explore** | Smart search (synonym-aware: "tacos" → restaurants), filter chips, business cards | ✅ Solid |
| **Map** | MapKit, grid-based clustering for 200+ pins, category chips, popup cards, offline fallback | ✅ Solid |
| **Tools** | Currency converter (live rates), tip calculator, phrasebook (audio), safety card, settings | ✅ Solid |
| **Trip** | Day-by-day itinerary view, Claude-backed AI generator (Insider+), saved favorites segment | ✅ Just shipped |
| **(Saved)** | Folded into Trip — favorites live there now | ✅ |

### Today's session shipped

1. **Reactions system** — heart / fire / thumbs on every business detail, optimistic UI, syncs to Supabase, aggregate counts shown to all users. Two devices verified, RLS protected, RPC-backed.
2. **Claude-backed itinerary generator** — Supabase Edge Function calling Sonnet 4.6 with prompt caching, structured outputs via `output_config.format`, candidate-pool pre-filtering, defense-in-depth ID validation. Falls back silently to the local heuristic when offline or backend errors. Returns a "Why these picks" rationale.
3. **Edge function tuning** — three iterations to land the prompt: (v1→v3) fixed Anthropic strict-mode schema rejection by reshaping `schedule` to an array; (v3→v4) added long-trip filling rules; (v4→v5) departure-day gets 1-2 light picks, never empty.
4. **Anon key plumbing** — moved from Info.plist (which Xcode 15+ silently drops for custom keys) to a constant in `AppConstants`. Standard pattern for Supabase apps; the anon key is public by design and protected by RLS.
5. **Reactions schema applied to production** — `business_reactions` table, `business_reaction_counts` view, `set_reactions` RPC, RLS policies. Live in Supabase project `vbxmmslzanixvqswtnnv`.

### Pre-existing strengths worth naming

- **Cruise day Live Activity** is fully wired (lock-screen countdown updates from `CruiseViewModel` via `LiveActivityManager`). Lock-screen sunset widget too.
- **Right Now feed** composes contextual cards from weather, reef score, business hours, and trip countdown. This is the brand-defining surface.
- **App Intents** wire the app into Spotlight and Siri. *"Hey Siri, show me dive shops in Roatán."*
- **Smart search** with synonym matching — "snorkel" finds dive shops, "lounge" finds nightlife.
- **Onboarding 2.0** — six optional steps (traveler type, dates, interests, permissions). Profile-optional throughout.
- **StoreKit 2** with grandfather cohort for pre-2.0.0 $4.99 buyers (founding members never see a paywall).
- **Deep linking router** — every business has a canonical `slug` URL.
- **49 haptic call sites** — the app feels tactile.
- **Spanish localization** plumbing in place via String Catalog.

### Operational health

| | Status |
|---|---|
| Analytics events defined | ✅ Comprehensive |
| Analytics backend connected | ⚠️ TelemetryDeck configured but not active |
| Crash reporting | ❌ Not wired |
| Privacy manifest | ✅ Present |
| Universal links | ✅ Router in place |
| Cloud-synced favorites | ❌ Referenced in paywall copy, not built |
| Offline map tiles | ❌ Referenced in paywall copy, not built |
| Drag-to-reorder itinerary | ⚠️ Stubs only |
| Spanish UI coverage | ⚠️ Strings present, UI mostly English |

---

## Data depth + gaps

**94 verified businesses** across 10 categories and 11 areas. 17 featured, 12 insider picks.

By category, biggest to smallest: Eat 23 · Drink 12 · Dive 11 · Tours 11 · Shop 10 · Stay 10 · Beaches 8 · Nightlife 4 · Rentals 3 · Transport 2.

**The east-side coverage gap is real.** West End (38) + West Bay (27) = 69% of the catalog. Everything east of Coxen Hole — French Harbour, Oak Ridge, Punta Gorda, Port Royal, Camp Bay, Palmetto Bay, Dixon Cove, Johnson Bight combined — is 29% (27 businesses). This makes the app feel like a "Western Tip" guide rather than a "Roatán" guide. For cruise passengers it's fine (they only see the west anyway). For expats, long-stay, and repeat visitors, it's a credibility issue.

---

## The WOW deep dive

These are organized as **campaigns** — themed groupings of work that each, on their own, would constitute a "major update." The intent is each campaign produces one **wow moment** that a real user would tell a friend about.

I've assigned each item a rough effort tier (S = hours, M = days, L = weeks) and a confidence-weighted impact rating.

---

### Campaign A — *"Make Claude the soul of the app"*

The itinerary generator is already in. But Claude can do far more than schedule
days. The opportunity is to make every surface feel like there's an actual local
on the other end of the screen.

#### A1. **"Ask a Local" → real conversational AI**  ★★★★★  (M, ~3-5 days)

Today, `ask-a-local.json` is a static Q&A list (20-ish entries). Replace it with
a chat surface backed by Claude Haiku 4.5 (fast, cheap, perfect for Q&A) with the
businesses catalog + essentials + area guides loaded into a prompt-cached
system prompt. Users ask anything — *"where can I find pupusas under $5"*,
*"is West End safe at night for a solo female traveler"*, *"is the iguana farm
open on Sundays"* — and Claude answers with citations to the actual business
data. Cached system prompt means dirt cheap per query (~$0.001 with cache hits).

This is the demo that gets installs. Other guidebooks have static FAQs. Nobody
has *"the island, in a chat box, that knows everything you've already looked at."*

#### A2. **Personalized morning briefing**  ★★★★☆  (M, ~2-3 days)

7am push notification, Insider+ only:

> ☀️ *Tuesday in Roatán — sun, 84°, sunset 5:42pm.*  
> *Two cruise ships in port (Coxen Hole will be busy). Tongs Thai has live music tonight at 8.*  
> *Plan today? →*

Claude generates the line per active user nightly. Use the prompt cache pattern — system prompt is the same, the variable is "today's weather + ships + your interests + your favorites." Costs ~$0.002 per user per day.

This is the kind of thing that gets the app on the home screen instead of buried in a folder.

#### A3. **Trip recap "story"**  ★★★☆☆  (S, ~1 day)

When a user's `departureDate` passes, generate a one-screen recap:

> *You spent 7 days on Roatán. Your favorite area was West End — you went back three times. Sundowners was your last sunset. You snorkeled 4 reefs.*  
> *Hope you come back. — RI*

Save as a shareable card image. Emails too if they opted in. Emotional resonance + remarketing hook. Other apps don't do this because they don't have the data; you do.

---

### Campaign B — *"Own the cruise day"*

Cruise passengers are the highest-LTV segment by volume: 1M+ per year on
Roatán, urgent decision-making in a 6-8 hour window, paying for short-term
value. The cruise mode exists but it's not where it could be.

#### B1. **Ship tracking + crowd predictions**  ★★★★★  (M, ~3-4 days)

Free APIs (CruiseMapper, MarineTraffic) give real-time cruise schedules:

> *Mahogany Bay today: Carnival Magic + Norwegian Joy (5,800 passengers, in port until 4pm). West End will be quiet until 1pm.*

Surfaced in Right Now feed AND on the cruise mode screen. Useful for cruise
passengers ("don't go where the crowds go") AND for stay-over travelers
("avoid Coxen Hole today"). Genuine information arbitrage — nobody else does
this for Roatán.

Bonus: the Live Activity countdown can auto-adjust if the ship is delayed.

#### B2. **"Insider Pass" partnerships with real discounts**  ★★★★★  (L, ~2 weeks setup + ongoing)

Josh lives in West Bay and knows the owners. The bones already exist in the
paywall copy ("Insider Pass discounts"). Make it real:

- Approach 8-12 businesses for a partnership: 10-20% off, 2-for-1 happy hour, free dessert with entrée
- Each business gets a "Roatán Insider Partner" sticker for their door — free advertising
- App shows the discount as a tappable card on the business detail page (Insider+ only)
- Tap → fullscreen QR with the user's anon device ID encoded. Owner scans (or just shows on phone)
- One drink saving pays for the year of Insider+

This is the single biggest reason a cruise passenger would tap "subscribe" in
their 6-hour window.

#### B3. **Auto-detect arrival**  ★★★☆☆  (S, ~1 day)

When the app launches in Roatán for the first time (CLLocation geofence on the
island), trigger cruise mode automatically if no trip dates are set. *"Welcome
to Roatán — looks like a cruise day. Tap to plan your hours."* Zero friction.

#### B4. **East-side content fill**  ★★★☆☆  (L, ~1 week of writing + photo sourcing)

Add 15-20 businesses for French Harbour, Oak Ridge, Punta Gorda, Camp Bay, Port
Royal. Targets the expat / long-stay / repeat-visitor segment that today gets
the least value. Also enables the "let's drive east today" itinerary that
Claude currently can't generate well because the candidate pool is thin.

---

### Campaign C — *"Make it feel alive"*

The app is content-rich but the *content* is static. Photos don't move, owners
don't speak, and the social signal is buried.

#### C1. **Trending reactions on Home**  ★★★★☆  (S, ~half a day)

Surface a "Trending this week" section pulling top-reacted businesses from the
last 7 days. We have the data live in `business_reactions`. Single SQL view,
single Home section, virtuous cycle (popular places → more visibility → more
reactions → more popular).

#### C2. **6-second video loops on business detail**  ★★★★☆  (M, content-bound)

Every business detail has a photo gallery. Add an optional `videoLoop` field
(short MP4 in Supabase Storage). Sunset Bananarama, sea breeze on Half Moon
Bay, the dive boat leaving. Doesn't need to be every business — even 15-20
hand-picked ones change the texture of the whole app from "guide" to
"experience."

#### C3. **Owner voice memos**  ★★★★★  (M, content-bound)

A 30-second audio intro from the actual owner, played from a small ▶ button on
the detail page.

> *"Hi, I'm Maria from Eldons. We open at 5am because that's when the
> fishermen come in. Cash only — there's an ATM next door at the gas station."*

Nobody does this. Not TripAdvisor, not Yelp, not Atlas Obscura, not the cruise
line concierge. It's the literal embodiment of *"Explore the island like a
local."* Even 8-10 of these would be the single most distinctive feature in the
app.

#### C4. **Shareable trip plans**  ★★★★☆  (M, ~2-3 days)

Once a user has a plan, generate a beautiful share card: *"My 5 days in
Roatán — by [Name]"* with the day-by-day. Friends see it on iMessage / IG, tap
to install. Currently only individual businesses share. This is your viral
loop.

---

### Campaign D — *"Operational maturity"*

These won't WOW users but they're load-bearing for everything else.

| Item | Effort | Why |
|---|---|---|
| **Turn on TelemetryDeck** | S | Currently flying blind on what people actually use. Already configured. |
| **Add Sentry crash reporting** | S | Production crashes are invisible. Free tier covers us 100x over. |
| **Build OR remove "Cloud favorites"** | M / S | Paywall claims it. Either CloudKit (easy with SwiftData) or remove the claim. App-Review-risk to leave as-is. |
| **Build OR remove "Offline map tiles"** | M / S | Same as above. MKMapView caching is straightforward; or remove the bullet. |
| **Finish drag-to-reorder itinerary** | S | Stubs already in place. A few hours. |
| **Complete Spanish UI coverage** | M | Strings in catalog. UI is still mostly English. Big deal for an island where Spanish is the local language + huge LatAm cruise market. |
| **Remove temporary debug print** | already done ✅ | |

---

## Recommended sequence

If I'm sequencing these for maximum impact-per-day:

**Week 1 — Foundations + first WOW (parallel tracks):**
- Op-maturity track: TelemetryDeck on, Sentry on, decide cloud-favorites / offline-maps (build or remove).
- Feature track: **Trending reactions on Home (C1)** + **Auto-detect arrival (B3)** — both small, both visible.

**Week 2-3 — The first real WOW:**
- **Conversational Ask a Local (A1)** — this is the demo. Backed by Haiku 4.5, cached prompt, the existing data.

**Week 3-4 — Cruise day expansion:**
- **Ship tracking + crowd predictions (B1)** — the data exists, the implementation is plumbing.
- Start the **Insider Pass partnership outreach (B2)** in parallel — that's people-work, not code-work, Josh's natural strength.

**Week 4-6 — Soul:**
- **Owner voice memos (C3)** — even 8 of these change the app's identity. Josh records them himself with the owners he knows.
- **Personalized morning briefing (A2)** — quiet daily push that builds habit.

**Week 6-8 — Polish before press:**
- **Shareable trip plans (C4)** — viral loop on top of an app people now love.
- **East-side content fill (B4)** — opens the long-stay market.
- **Spanish UI completion**.
- **Trip recap story (A3)** — emotional close to the experience.

That's 6-8 weeks to a major update with multiple genuine WOW moments. Each
campaign produces one thing a user would mention out loud.

---

## Setup state (preserved for resuming)

- **Reactions backend:** Live. Schema applied via Supabase MCP. Anon key in source (`AppConstants.swift`).
- **Itinerary backend:** Live, Edge Function v5. `ANTHROPIC_API_KEY` set in Supabase dashboard → Edge Functions → Secrets.
- **Branch:** `claude/roatan-app-redesign-CtjgW` (pull and ⌘R works).
- **Supabase project:** `vbxmmslzanixvqswtnnv` (region: us-east-1).
- **Model in use:** `claude-sonnet-4-6` for itineraries. Recommend `claude-haiku-4-5` for Ask-a-Local + morning briefing when those ship (10x cheaper, fast enough).

---

## What I'd watch out for

- **The cloud-favorites and offline-maps paywall claims** are the single most
  likely thing to trip up App Review. Build them or remove the claims before
  the next submission. Don't ship the current paywall to App Store as-is.
- **No crash reporting** means we'll discover production bugs only via App
  Store reviews. Wire Sentry before the major update goes live.
- **Anthropic billing** for itineraries is currently uncapped. Once usage
  scales, either flip `verify_jwt` on for the edge function (forces real auth)
  or add a daily per-device rate limit. Currently anyone with the anon key
  could drain the API budget.
- **94 businesses is good but not yet "comprehensive Roatán."** Either fill
  out the east side or own the framing as "the West End / West Bay insider
  guide." Both are valid product positions; pick one.
- **The grandfather cohort** is generous (anyone with `originalAppVersion <
  2.0.0` gets Insider+ free forever). Make sure marketing for the major
  update doesn't accidentally invalidate this — those are your loudest fans.

---

*Authored alongside Josh Green by Claude (claude-opus-4-7), 20 May 2026.*
