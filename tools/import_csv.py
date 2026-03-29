#!/usr/bin/env python3
"""
Import businesses_edit.csv back into businesses.json.

Reads the CSV (exported by export_csv.py or edited by hand), converts
each row to a full business JSON object, and writes businesses.json.

Also writes a manifest.json you can upload to Supabase alongside the
businesses.json to trigger app updates.

Usage:
    python3 tools/import_csv.py                    # convert and write JSON
    python3 tools/import_csv.py --dry-run          # preview without writing
    python3 tools/import_csv.py --bump-version     # also bump manifest.json version
"""

import argparse
import csv
import json
import os
import re
import sys
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DEFAULT_CSV = os.path.join(PROJECT_ROOT, "businesses_edit.csv")
JSON_PATH = os.path.join(PROJECT_ROOT, "RoatanInsider", "Data", "businesses.json")
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "manifest.json")

AREA_MAP = {
    "west bay": "west_bay",
    "west end": "west_end",
    "sandy bay": "sandy_bay",
    "coxen hole": "coxen_hole",
    "flowers bay": "flowers_bay",
    "french harbour": "french_harbour",
    "oak ridge": "oak_ridge",
    "punta gorda": "punta_gorda",
    "port royal": "port_royal",
    "camp bay": "camp_bay",
    "dixon cove": "dixon_cove",
    "palmetto bay": "palmetto_bay",
    "milton bight": "milton_bight",
    "johnson bight": "johnson_bight",
}

CATEGORY_MAP = {
    "eat": "eat",
    "drink": "drink",
    "dive": "dive",
    "dive & snorkel": "dive",
    "tours": "tours",
    "tours & activities": "tours",
    "shop": "shop",
    "stay": "stay",
    "rentals": "rentals",
    "transport": "transport",
    "beaches": "beaches",
    "nightlife": "nightlife",
}


def val(row, key):
    """Get a trimmed value from a CSV row."""
    v = row.get(key, "")
    return v.strip() if v else ""


def is_yes(v):
    return v.strip().lower() == "yes" if v else False


def slugify(name):
    slug = name.lower().strip()
    slug = re.sub(r"[''']", "", slug)
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    return slug.strip("-")


def parse_price(s):
    if not s:
        return 1
    count = s.count("$")
    return max(1, min(4, count)) if count else 1


def normalize_area(s):
    if not s:
        return "west_bay"
    key = s.strip().lower()
    if key in AREA_MAP:
        return AREA_MAP[key]
    # Already a raw value?
    if key.replace(" ", "_") in AREA_MAP.values():
        return key.replace(" ", "_")
    return key.replace(" ", "_")


def normalize_category(s):
    if not s:
        return "eat"
    key = s.strip().lower()
    if key in CATEGORY_MAP:
        return CATEGORY_MAP[key]
    return key


def parse_list(s):
    """Parse a comma-separated string into a list, filtering blanks."""
    if not s:
        return []
    return [item.strip() for item in s.split(",") if item.strip()]


def parse_additional_cats(s):
    """Parse 'cat:subcat | cat:subcat' into list of dicts."""
    if not s:
        return []
    result = []
    for part in s.split("|"):
        part = part.strip()
        if ":" in part:
            cat, sub = part.split(":", 1)
            cat = normalize_category(cat.strip())
            sub = sub.strip()
            if cat and sub:
                result.append({"category": cat, "subcategory": sub})
    return result


def parse_additional_locs(s):
    """Parse 'area:lat:lon:address | ...' into list of dicts."""
    if not s:
        return []
    result = []
    for part in s.split("|"):
        part = part.strip()
        pieces = part.split(":", 3)
        if len(pieces) >= 3:
            try:
                result.append({
                    "area": normalize_area(pieces[0].strip()),
                    "latitude": float(pieces[1].strip()),
                    "longitude": float(pieces[2].strip()),
                    "addressDescription": pieces[3].strip() if len(pieces) > 3 else "",
                })
            except ValueError:
                pass
    return result


def parse_float(s):
    if not s:
        return None
    try:
        return float(s)
    except ValueError:
        return None


def parse_int(s):
    if not s:
        return None
    try:
        return int(float(s))
    except ValueError:
        return None


DAYS_OF_WEEK = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

# Map day abbreviations to full names
DAY_ABBREV = {
    "mon": "monday", "tue": "tuesday", "tues": "tuesday", "wed": "wednesday",
    "thu": "thursday", "thur": "thursday", "thurs": "thursday",
    "fri": "friday", "sat": "saturday", "sun": "sunday",
}


def parse_time_12h(s):
    """Convert '8am', '3pm', '11:30am', '12pm', '6:30pm' to 24h 'HH:MM'."""
    s = s.strip().lower().replace(".", "")
    is_pm = "pm" in s
    is_am = "am" in s
    s = s.replace("am", "").replace("pm", "").strip()

    if ":" in s:
        parts = s.split(":")
        hour = int(parts[0])
        minute = int(parts[1])
    else:
        hour = int(s)
        minute = 0

    if is_pm and hour != 12:
        hour += 12
    if is_am and hour == 12:
        hour = 0

    return f"{hour:02d}:{minute:02d}"


def expand_day_range(range_str):
    """Expand 'Mon-Fri' to ['monday','tuesday','wednesday','thursday','friday']."""
    range_str = range_str.strip().lower()

    # Check for "daily"
    if range_str == "daily":
        return list(DAYS_OF_WEEK)

    # Single day
    if range_str in DAY_ABBREV:
        return [DAY_ABBREV[range_str]]
    if range_str in DAYS_OF_WEEK:
        return [range_str]

    # Range like "Mon-Fri" or "Tue-Sun"
    for sep in ["–", "-", "—"]:
        if sep in range_str:
            parts = range_str.split(sep)
            if len(parts) == 2:
                start = parts[0].strip()
                end = parts[1].strip()
                start_name = DAY_ABBREV.get(start, start)
                end_name = DAY_ABBREV.get(end, end)
                if start_name in DAYS_OF_WEEK and end_name in DAYS_OF_WEEK:
                    si = DAYS_OF_WEEK.index(start_name)
                    ei = DAYS_OF_WEEK.index(end_name)
                    if ei >= si:
                        return DAYS_OF_WEEK[si:ei + 1]
                    else:
                        # Wraps around: e.g. Fri-Mon
                        return DAYS_OF_WEEK[si:] + DAYS_OF_WEEK[:ei + 1]
            break

    return []


def parse_hours_text(hours_text):
    """
    Parse human-readable hours into structured format.

    Examples:
        "Daily 11am-10pm"
        "Mon-Fri 8am-3pm; Sat 8am-6pm; Closed Sun"
        "Tue-Sun 3pm-9pm; Closed Mon"
        "Mon-Sat 7am-10pm; Closed Sun"
        "Daily 24 hours"
    """
    if not hours_text:
        return None

    hours = {day: None for day in DAYS_OF_WEEK}
    segments = [seg.strip() for seg in hours_text.replace(",", ";").split(";")]

    for segment in segments:
        segment = segment.strip()
        if not segment:
            continue

        lower = segment.lower()

        # "Closed Mon" or "Closed Sunday"
        if lower.startswith("closed"):
            rest = lower.replace("closed", "").strip()
            if rest:
                days = expand_day_range(rest)
                for d in days:
                    hours[d] = None
            continue

        # Try to split into days + times
        # "Daily 11am-10pm", "Mon-Fri 8am-3pm", "Sat 8am-6pm"
        parts = segment.split(" ", 1)
        if len(parts) < 2:
            continue

        day_part = parts[0]
        time_part = parts[1].strip()

        # Handle "24 hours"
        if "24" in time_part.lower() and "hour" in time_part.lower():
            days = expand_day_range(day_part)
            for d in days:
                hours[d] = {"open": "00:00", "close": "23:59"}
            continue

        # Parse time range "8am-3pm" or "8am–3pm"
        time_range = None
        for sep in ["–", "-", "—", "to"]:
            if sep in time_part:
                time_parts = time_part.split(sep, 1)
                if len(time_parts) == 2:
                    try:
                        open_time = parse_time_12h(time_parts[0])
                        close_time = parse_time_12h(time_parts[1])
                        time_range = {"open": open_time, "close": close_time}
                    except (ValueError, IndexError):
                        pass
                break

        if time_range:
            days = expand_day_range(day_part)
            for d in days:
                hours[d] = time_range

    # Only return if we successfully parsed at least one day
    if any(v is not None for v in hours.values()):
        return hours

    return None


def row_to_business(row, existing_by_id):
    """Convert a CSV row to a business dict, preserving structured hours from existing JSON."""
    bid = val(row, "ID")
    if not bid:
        return None

    name = val(row, "Name")
    if not name:
        return None

    slug = val(row, "Slug") or slugify(name)

    # Start from existing business if available (preserves structured hours, etc.)
    existing = existing_by_id.get(bid, {})

    business = {
        "id": bid,
        "slug": slug,
        "name": name,
        "description": val(row, "Description"),
        "insiderTip": val(row, "Insider Tip") or None,
        "category": normalize_category(val(row, "Category")),
        "subcategory": val(row, "Subcategory"),
        "area": normalize_area(val(row, "Area")),
        "latitude": parse_float(val(row, "Latitude")) or existing.get("latitude", 16.3),
        "longitude": parse_float(val(row, "Longitude")) or existing.get("longitude", -86.5),
        "addressDescription": val(row, "Address Description"),
        "phone": val(row, "Phone") or None,
        "whatsapp": val(row, "WhatsApp") or None,
        "email": val(row, "Email") or None,
        "website": val(row, "Website") or None,
        "facebook": val(row, "Facebook") or None,
        "instagram": val(row, "Instagram") or None,
        "priceRange": parse_price(val(row, "Price Range")),
        # Parse hours from CSV Hours Text; fall back to existing structured hours
        "hours": parse_hours_text(val(row, "Hours Text")) or existing.get("hours", {}),
        "hoursText": val(row, "Hours Text") or existing.get("hoursText") or None,
        "features": parse_list(val(row, "Features")),
        "images": parse_list(val(row, "Images")) or existing.get("images", ["business_placeholder"]),
        "isVerified": is_yes(val(row, "Verified")),
        "isFeatured": is_yes(val(row, "Featured")),
        "isInsiderPick": is_yes(val(row, "Insider Pick")),
        "isBestOf": is_yes(val(row, "Best Of")),
        "rating": parse_float(val(row, "Rating")),
        "reviewCount": parse_int(val(row, "Review Count")),
        "status": val(row, "Status") or "active",
        "collections": parse_list(val(row, "Collections")),
        "menuImages": parse_list(val(row, "Menu Images")) or None,
        "additionalCategories": parse_additional_cats(val(row, "Additional Categories")),
        "additionalLocations": parse_additional_locs(val(row, "Additional Locations")),
    }

    return business


def main():
    parser = argparse.ArgumentParser(description="Import CSV back into businesses.json")
    parser.add_argument("--csv", default=DEFAULT_CSV, help="Input CSV path")
    parser.add_argument("--json", default=JSON_PATH, help="Output JSON path")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    parser.add_argument("--bump-version", action="store_true",
                        help="Bump manifest.json version for Supabase updates")
    args = parser.parse_args()

    if not os.path.exists(args.csv):
        print(f"❌ CSV not found: {args.csv}")
        print(f"   Run 'python3 tools/export_csv.py' first to create it.")
        sys.exit(1)

    # Load existing JSON to preserve structured hours
    existing_by_id = {}
    # Always read from the standard path to preserve structured hours,
    # even if writing to a different output path
    existing_path = JSON_PATH if os.path.exists(JSON_PATH) else args.json
    if os.path.exists(existing_path):
        with open(existing_path, "r", encoding="utf-8") as f:
            for b in json.load(f):
                existing_by_id[b["id"]] = b

    # Read CSV
    with open(args.csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    # Convert
    businesses = []
    skipped = 0
    for row in rows:
        b = row_to_business(row, existing_by_id)
        if b:
            businesses.append(b)
        else:
            skipped += 1

    businesses.sort(key=lambda b: b["id"])

    # Stats
    active = sum(1 for b in businesses if b["status"] == "active")
    featured = sum(1 for b in businesses if b["isFeatured"])
    insider = sum(1 for b in businesses if b["isInsiderPick"])

    print()
    print("=" * 50)
    print("IMPORT SUMMARY")
    print("=" * 50)
    print(f"  CSV rows:        {len(rows)}")
    print(f"  Businesses:      {len(businesses)}")
    print(f"  Skipped:         {skipped}")
    print(f"  Active:          {active}")
    print(f"  Featured:        {featured}")
    print(f"  Insider Picks:   {insider}")
    print()

    if args.dry_run:
        print("[DRY RUN] No files written.")
        return

    # Write JSON
    with open(args.json, "w", encoding="utf-8") as f:
        json.dump(businesses, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"✅ Wrote {len(businesses)} businesses to {args.json}")

    # Bump manifest
    if args.bump_version:
        manifest = {"version": 1, "updatedAt": ""}
        if os.path.exists(MANIFEST_PATH):
            with open(MANIFEST_PATH, "r") as f:
                manifest = json.load(f)

        manifest["version"] = manifest.get("version", 0) + 1
        manifest["updatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        with open(MANIFEST_PATH, "w") as f:
            json.dump(manifest, f, indent=2)
            f.write("\n")
        print(f"✅ Bumped manifest to v{manifest['version']}")
        print()
        print("Next steps:")
        print(f"  1. Upload {args.json} to Supabase → app-data bucket")
        print(f"  2. Upload {MANIFEST_PATH} to Supabase → app-data bucket")
    else:
        print()
        print("To push to the app, run again with --bump-version:")
        print("  python3 tools/import_csv.py --bump-version")


if __name__ == "__main__":
    main()
