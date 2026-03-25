# Roatán Insider — Business Data Verification Cowork Prompt

Copy everything below the line and paste it as your prompt to Claude. Point it at your local copy of the repository.

---

## Your Task

You are verifying and completing business data for the Roatán Insider iOS app — a premium travel guide for Roatán, Honduras priced at $4.99. Every piece of data must be accurate. Tourists will rely on this information.

### Files You'll Work With

1. **`businesses_curation.csv`** — The master curation spreadsheet. This is where you mark corrections.
2. **`RoatanInsider/Data/businesses.json`** — The full business data with descriptions, hours, coordinates, contact info. You will update this file directly for fields not covered by the CSV.

### What To Verify For EVERY Business Where `KEEP? = yes`

For each kept business, web search for the business by name + "Roatán Honduras" and verify:

#### 1. GPS Coordinates (Critical)
- Search Google Maps or similar for the exact business location
- Compare to the LATITUDE and LONGITUDE columns in the CSV
- Roatán coordinates are always: latitude ~16.2–16.45, longitude ~-86.2 to -86.6
- If wrong, put the corrected values in `LAT OVERRIDE` and `LON OVERRIDE` in the CSV
- If correct, put `yes` in `LAT CORRECT?`
- Be precise to 6 decimal places

#### 2. Business Hours
- Search for current hours on Google, Facebook, TripAdvisor, or the business website
- Compare to the `hours` field in businesses.json
- If the hours in the JSON are wrong or outdated, update them directly in businesses.json
- Put `yes` in `HOURS CORRECT?` in the CSV if verified, or corrections in `HOURS NOTES`
- Common patterns on Roatán: restaurants 11am-9pm, dive shops 7am-5pm, bars 11am-midnight
- Many places are closed 1-2 days per week — verify which days

#### 3. Contact Information (Update directly in businesses.json)
For each business, find and fill in ALL available contact info:
- `phone` — Local phone number with country code (format: "+504 XXXX-XXXX")
- `whatsapp` — WhatsApp number (often same as phone, format: "50498765432")
- `email` — Business email
- `website` — Full URL including https://
- `facebook` — Full Facebook page URL
- `instagram` — Instagram handle with @ (e.g., "@sundownersroatan")

Sources to check: Google Maps listing, Facebook page, TripAdvisor, the business's own website, Instagram bio.

#### 4. Ratings & Reviews (Update in businesses.json)
- `rating` — Google Maps rating (1.0-5.0 scale, one decimal)
- `reviewCount` — Approximate Google review count
- If a business has no rating currently (`null`), search for it

#### 5. Description Quality Check
- Read the current `description` in businesses.json
- If it contains factual errors based on your research, fix them
- If it's too short (under 80 chars), expand it to 100-200 words
- Keep the voice: insider, specific, honest, practical — NOT promotional or flowery
- Do NOT rewrite descriptions that are already good

#### 6. Insider Tips
- If `insiderTip` is null, add one based on real reviews/knowledge
- Tips should be specific and actionable: "Ask for the catch of the day — it's not on the menu"
- NOT generic: "Great place to visit!"

### Businesses That Are Merged

Some businesses have `MERGE INTO` set in the CSV. These are being combined into a single listing. For merged targets (the business that absorbs others), make sure the description in businesses.json covers ALL the services. For example, Anthony's Key Resort (b161) should mention the resort, dive center, AND restaurant.

### Multi-Category Businesses

Businesses with `additionalCategories` in the JSON should have descriptions that naturally mention all their services without feeling forced.

### What NOT To Do

- Do NOT change `id`, `slug`, or `category` fields
- Do NOT change the `KEEP?` or `MERGE INTO` columns — those are set
- Do NOT add businesses that aren't in the CSV
- Do NOT make up data you can't verify — if you can't find hours, leave them and note "unable to verify" in HOURS NOTES
- Do NOT change the CSV column structure

### How To Process

Work through businesses in batches of 10-15. For each batch:

1. Read the business entries from businesses.json
2. Web search each business name + "Roatán"
3. Update businesses.json with corrected/new contact info, hours, ratings, descriptions
4. Update businesses_curation.csv with LAT CORRECT?, LAT/LON OVERRIDE, HOURS CORRECT?, HOURS NOTES
5. Save both files after each batch

### Priority Order

Start with **Featured businesses** (FEATURED? = yes), then **Insider Picks**, then the rest. Featured businesses are the ones users see first — they must be perfect.

### After All Businesses Are Verified

Run this command to regenerate businesses.json from the CSV overrides:
```
python3 tools/csv_to_json.py
```

Then verify the output:
```
python3 tools/csv_to_json.py --dry-run
```

### Quick Reference: Roatán Areas

| Area | Where | Coordinates Center |
|------|-------|--------------------|
| West Bay | Tourist beach, south tip | 16.275, -86.599 |
| West End | Backpacker/diver village | 16.305, -86.593 |
| Sandy Bay | Between West End & Coxen Hole | 16.320, -86.575 |
| Coxen Hole | Main town, cruise port | 16.315, -86.545 |
| French Harbour | Commercial center, east | 16.350, -86.460 |
| Dixon Cove | Mahogany Bay cruise port | 16.328, -86.498 |
| Oak Ridge | Fishing village, east | 16.390, -86.356 |
| Palmetto Bay | Valley area, south shore | 16.360, -86.485 |
| Punta Gorda | Garifuna village, east | 16.413, -86.364 |
| Camp Bay | Remote east end | 16.430, -86.293 |

If a business's coordinates don't fall near its listed area, something is wrong.
