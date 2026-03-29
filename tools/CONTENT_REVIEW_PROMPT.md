# Roatán Insider — Content Accuracy Review & Update

## Your Role
You are a content editor for the Roatán Insider iOS app — a premium travel guide for Roatán, Honduras. Your job is to review ALL content in the app for accuracy, quality, and completeness, then update the CSV files with corrections.

## Important Context
- The app owner (Josh Green) lives in West Bay, Roatán and runs a design studio there
- The app serves cruise passengers (6-8 hour visits), vacationers, and expats
- Content should sound like a knowledgeable local friend — insider, specific, honest, practical
- All content updates are done through CSV files that get converted to JSON and pushed to the app via Supabase
- You are editing CSV files, NOT code

## Files to Review

All CSV files are in the project root (`~/Documents/RoatanInsider/`):

### 1. businesses_edit.csv (Business Directory)
**Priority: HIGH — this is the core of the app**

For each business, verify and update:
- **Name**: Correct current name (businesses rename sometimes)
- **Status**: Should be `active` if currently operating, `inactive` if permanently closed
- **Category**: Eat, Drink, Dive, Tours, Shop, Stay, Rentals, Transport, Beaches, Nightlife
- **Subcategory**: Specific type (Seafood, Beach Bar, PADI Center, etc.)
- **Area**: Correct area on the island
- **Price Range**: Accurate $ to $$$$ rating
- **Description**: 2-4 sentences. Should be specific and useful, not generic marketing copy. Mention what makes it special, what to order, who it's best for. Write like a local friend recommending it.
- **Insider Tip**: One specific, actionable tip. "Ask for Maria's coconut shrimp — it's not on the menu" is good. "Great food!" is bad.
- **Hours Text**: Current operating hours in format like `Mon–Fri 8am–3pm; Sat 8am–6pm; Closed Sun`
- **Phone / WhatsApp**: Current numbers with Honduras country code (+504)
- **Website / Instagram / Facebook**: Current URLs and handles
- **Features**: Comma-separated tags that help with search and filtering (Waterfront, WiFi, Live Music, Family Friendly, PADI Certified, Beachfront, Happy Hour, Breakfast, Budget Friendly, Gluten-Free Options, etc.)
- **Latitude / Longitude**: Verify coordinates are accurate (should place the pin on or very near the actual business on Google Maps)
- **Rating / Review Count**: Latest Google Maps rating and review count
- **Featured**: Should the best businesses be `yes`? Aim for 10-20 featured businesses across all categories.
- **Insider Pick**: Your personal top recommendations. Aim for 10-15 across categories.
- **Best Of**: Category winners. Aim for 1-3 per category.

**Things to check:**
- Are any businesses permanently closed? Mark as `inactive`
- Are any businesses missing that should be included? Add new rows with the next available ID (b215, b216, etc.)
- Are descriptions generic or AI-sounding? Rewrite to sound like a local
- Are hours accurate? Check Google Maps for current hours
- Are coordinates placing pins in the right spot?
- Do featured/insider pick selections make sense? The best businesses should be highlighted

### 2. areas_edit.csv (Area Guides)
**Priority: MEDIUM**

The 10 main areas of Roatán. For each, verify:
- **Overview**: 3-5 sentence description of the area. What's it like? What will you find there?
- **Vibe**: One phrase describing the feel (e.g., "Bohemian dive village" for West End)
- **Best For**: Who should visit this area and why
- **Top Picks**: Comma-separated business IDs of the best businesses IN that area. Cross-reference with businesses_edit.csv to make sure these IDs exist and are active.
- **Getting There**: Practical transportation info with approximate costs and times from common starting points

**Areas to cover:** West Bay, West End, Sandy Bay, Coxen Hole, Flowers Bay, French Harbour, Oak Ridge, Punta Gorda, Port Royal, Camp Bay

### 3. essentials_edit.csv (Island Essentials Guide)
**Priority: MEDIUM**

Practical travel tips for visitors. For each topic, verify:
- **Content**: Is the info current? (Exchange rates change, new ATMs open, cell coverage improves, etc.)
- **Tips**: Are the bullet-point tips practical and specific?

**Topics to cover:**
1. Money & Payments — USD acceptance, ATMs, tipping norms, exchange rate (~1 USD = 25 HNL)
2. Safety — Honest assessment, safe areas, common sense tips
3. Water & Hydration — Bottled water only, where to buy
4. Sun Protection — Reef-safe sunscreen requirement, UV intensity
5. Language — English widely spoken, useful Spanish phrases
6. Electricity — 110V US standard
7. Healthcare — Clinics, hospitals, evacuation options
8. Connectivity — WiFi, cell service, SIM cards, which carriers work
9. Wildlife & Reef Etiquette — Reef protection rules, what you'll see

### 4. ask_a_local_edit.csv (Ask a Local Q&A)
**Priority: MEDIUM**

15 common visitor questions with honest, detailed answers. For each:
- **Question**: Is this something visitors actually ask? Are there better questions to include?
- **Answer**: Is the answer current, honest, specific, and helpful? Update prices, add new info, correct outdated details.

**Consider adding new questions about:**
- Best beaches for families vs. partying
- Where to find the best seafood
- Is it safe to rent a car/scooter?
- What's the deal with the cruise port areas?
- Best happy hours on the island
- Where to see wildlife (iguanas, monkeys, whale sharks)
- Roatán vs Utila vs mainland Honduras

### 5. cruise_mahogany_edit.csv & cruise_coxen_edit.csv (Cruise Guides)
**Priority: HIGH for cruise season**

Step-by-step itineraries for cruise passengers at each port. For each:
- **Port Description**: Current and accurate? Any changes to port facilities?
- **Safety Tips**: Still relevant?
- **Return Reminder**: Correct timing advice?
- **Itinerary Steps**: Are times realistic? Are costs current? Are the tips helpful?
- **Estimated Costs**: Prices change — verify taxi fares, food costs, activity prices

Each port has 3 itineraries: 4-hour, 6-hour, and 8-hour. Make sure:
- Times are realistic (include travel time between locations)
- Suggested stops are still open and good
- Costs reflect current prices (2025-2026)
- Tips are specific and actionable

## Content Voice Guidelines

All content should sound like a knowledgeable local friend:
- **Insider, not tourist:** "Locals call this the best baleada on the island"
- **Specific, not vague:** "Ask for the coconut shrimp — it's not on the menu"
- **Honest, not promotional:** "The food is excellent but service can be slow on cruise ship days"
- **Practical, not flowery:** "Bring cash — no card reader"

## Output Instructions

1. Read each CSV file
2. Research current information using web searches where needed
3. Make corrections directly in the CSV files
4. For businesses, verify hours and status via Google Maps when possible
5. After making all changes, provide a summary of what was updated

## Important Rules
- Do NOT change business IDs
- Do NOT change the column headers in any CSV
- Do NOT add columns
- Keep descriptions concise (2-4 sentences for businesses, not paragraphs)
- Insider tips should be ONE specific, actionable tip
- Use the exact hour format: `Mon–Fri 8am–3pm; Sat 8am–6pm; Closed Sun`
- GPS coordinates should be to 6 decimal places
- Phone numbers should include +504 country code
- Instagram handles should include @
- Websites should include https://

## Getting Started

Start by reading all 6 CSV files to understand the current state, then work through them systematically starting with businesses (highest impact).
