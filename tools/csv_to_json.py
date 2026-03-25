#!/usr/bin/env python3
"""
Convert businesses_curation.csv into businesses.json.

Reads the CSV curation file and the existing businesses.json, merges them
according to the KEEP/override rules, and writes the updated JSON.

Usage:
    python3 tools/csv_to_json.py              # writes businesses.json
    python3 tools/csv_to_json.py --dry-run    # prints stats only
"""

import argparse
import csv
import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
CSV_PATH = os.path.join(PROJECT_ROOT, "businesses_curation.csv")
JSON_PATH = os.path.join(PROJECT_ROOT, "RoatanInsider", "Data", "businesses.json")

# Mapping from CSV Area display names to enum raw values
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

# Mapping from CSV Category display names to enum raw values
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

# Collection columns: CSV header -> collection key
COLLECTION_COLUMNS = {
    "COLLECTION: Sunset Spots": "sunset_spots",
    "COLLECTION: Families": "families",
    "COLLECTION: Cheap Eats": "cheap_eats",
    "COLLECTION: Beach Bars": "beach_bars",
    "COLLECTION: Off Beaten Path": "off_beaten_path",
    "COLLECTION: Cruise Must-Dos": "cruise_must_dos",
    "COLLECTION: Late Night": "late_night",
}


def is_yes(value):
    """Check if a CSV cell value means 'yes'."""
    return value.strip().lower() == "yes" if value else False


def slugify(name):
    """Generate a URL-friendly slug from a business name."""
    slug = name.lower().strip()
    slug = re.sub(r"[''']", "", slug)  # remove apostrophes
    slug = re.sub(r"[^a-z0-9]+", "-", slug)  # replace non-alphanum with hyphens
    slug = slug.strip("-")
    return slug


def parse_price_range(value):
    """Count $ signs in a price range string. Returns int 1-4."""
    if not value:
        return 1
    count = value.count("$")
    return max(1, min(4, count)) if count > 0 else 1


def normalize_area(area_str):
    """Convert area display name to enum raw value."""
    if not area_str:
        return "west_bay"
    key = area_str.strip().lower()
    # Try direct lookup first
    if key in AREA_MAP:
        return AREA_MAP[key]
    # Already a raw value?
    if key.replace(" ", "_") in AREA_MAP.values():
        return key.replace(" ", "_")
    # Try matching with underscores
    normalized = key.replace(" ", "_")
    for v in AREA_MAP.values():
        if v == normalized:
            return v
    return "west_bay"


def normalize_category(cat_str):
    """Convert category display name to enum raw value."""
    if not cat_str:
        return "eat"
    key = cat_str.strip().lower()
    if key in CATEGORY_MAP:
        return CATEGORY_MAP[key]
    # Already a raw value
    for v in CATEGORY_MAP.values():
        if v == key:
            return v
    return "eat"


def get_csv_value(row, key, default=""):
    """Safely get a value from a CSV row, returning default if missing or empty."""
    val = row.get(key, "")
    return val.strip() if val else default


def build_new_business(row):
    """Create a full business entry from CSV data for a new business."""
    name = get_csv_value(row, "Name") or get_csv_value(row, "NEW NAME") or "Unknown"
    slug = slugify(name)
    bid = get_csv_value(row, "ID")

    return {
        "id": bid,
        "slug": slug,
        "name": name,
        "description": get_csv_value(row, "Description (first 80 chars)"),
        "insiderTip": None,
        "category": normalize_category(get_csv_value(row, "Category")),
        "subcategory": get_csv_value(row, "Subcategory") or "",
        "area": normalize_area(get_csv_value(row, "Area")),
        "latitude": 16.3,
        "longitude": -86.5,
        "addressDescription": "",
        "phone": None,
        "whatsapp": None,
        "email": None,
        "website": None,
        "facebook": None,
        "instagram": None,
        "priceRange": parse_price_range(get_csv_value(row, "Price Range")),
        "hours": {},
        "hoursText": None,
        "features": [],
        "images": ["business_placeholder"],
        "isVerified": False,
        "isFeatured": False,
        "isInsiderPick": False,
        "isBestOf": False,
        "rating": None,
        "reviewCount": None,
        "status": get_csv_value(row, "Status") or "active",
        "collections": [],
        "menuImages": None,
    }


def apply_overrides(business, row, available_columns):
    """Apply CSV override fields to a business entry."""
    # FEATURED?
    featured_val = get_csv_value(row, "FEATURED? (yes/no)")
    if featured_val:
        business["isFeatured"] = is_yes(featured_val)

    # INSIDER PICK?
    insider_val = get_csv_value(row, "INSIDER PICK? (yes/no)")
    if insider_val:
        business["isInsiderPick"] = is_yes(insider_val)

    # BEST OF?
    bestof_val = get_csv_value(row, "BEST OF? (yes/no)")
    if bestof_val:
        business["isBestOf"] = is_yes(bestof_val)

    # NEW NAME
    new_name = get_csv_value(row, "NEW NAME")
    if new_name:
        business["name"] = new_name
        business["slug"] = slugify(new_name)

    # LAT OVERRIDE
    lat_str = get_csv_value(row, "LAT OVERRIDE")
    if lat_str:
        try:
            business["latitude"] = float(lat_str)
        except ValueError:
            pass

    # LON OVERRIDE
    lon_str = get_csv_value(row, "LON OVERRIDE")
    if lon_str:
        try:
            business["longitude"] = float(lon_str)
        except ValueError:
            pass

    # Collections
    collections = []
    for col_header, col_key in COLLECTION_COLUMNS.items():
        if col_header in available_columns:
            if is_yes(get_csv_value(row, col_header)):
                collections.append(col_key)
    business["collections"] = collections

    # Photo count -> images
    photo_count_str = get_csv_value(row, "PHOTO COUNT")
    if photo_count_str:
        try:
            photo_count = int(photo_count_str)
            if photo_count > 0:
                slug = business["slug"]
                business["images"] = [f"{slug}-{i+1}" for i in range(photo_count)]
        except ValueError:
            pass

    # Menu images
    has_menu = is_yes(get_csv_value(row, "HAS MENU?"))
    menu_count_str = get_csv_value(row, "MENU PHOTO COUNT")
    if has_menu and menu_count_str:
        try:
            menu_count = int(menu_count_str)
            if menu_count > 0:
                slug = business["slug"]
                business["menuImages"] = [f"{slug}-menu-{i+1}" for i in range(menu_count)]
            else:
                business["menuImages"] = None
        except ValueError:
            business["menuImages"] = None
    else:
        # Only set menuImages if not already present
        if "menuImages" not in business:
            business["menuImages"] = None

    # Ensure collections field exists even if no collection columns in CSV
    if "collections" not in business:
        business["collections"] = []

    return business


def ensure_new_fields(business):
    """Ensure the new fields (collections, menuImages) exist on every business."""
    if "collections" not in business:
        business["collections"] = []
    if "menuImages" not in business:
        business["menuImages"] = None
    return business


def main():
    parser = argparse.ArgumentParser(
        description="Convert businesses_curation.csv into businesses.json"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print stats without writing the output file",
    )
    parser.add_argument(
        "--csv",
        default=CSV_PATH,
        help=f"Path to CSV file (default: {CSV_PATH})",
    )
    parser.add_argument(
        "--json",
        default=JSON_PATH,
        help=f"Path to JSON file (default: {JSON_PATH})",
    )
    args = parser.parse_args()

    # Read existing JSON
    existing = {}
    if os.path.exists(args.json):
        with open(args.json, "r", encoding="utf-8") as f:
            data = json.load(f)
            for b in data:
                existing[b["id"]] = b
        print(f"Loaded {len(existing)} existing businesses from JSON")
    else:
        print(f"No existing JSON found at {args.json}, starting fresh")

    # Read CSV
    if not os.path.exists(args.csv):
        print(f"ERROR: CSV file not found at {args.csv}")
        sys.exit(1)

    with open(args.csv, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        available_columns = set(reader.fieldnames or [])
        rows = list(reader)

    print(f"Read {len(rows)} rows from CSV")
    print(f"CSV columns: {sorted(available_columns)}")

    # Process rows
    kept_ids = set()
    stats = {"kept": 0, "skipped": 0, "new": 0, "updated": 0}

    output = []

    for row in rows:
        bid = get_csv_value(row, "ID")
        if not bid:
            stats["skipped"] += 1
            continue

        keep_val = get_csv_value(row, "KEEP? (yes/no)")
        if not is_yes(keep_val):
            stats["skipped"] += 1
            continue

        stats["kept"] += 1
        kept_ids.add(bid)

        if bid in existing:
            # Use existing data as base, apply overrides
            business = dict(existing[bid])  # shallow copy
            business = ensure_new_fields(business)
            business = apply_overrides(business, row, available_columns)
            stats["updated"] += 1
        else:
            # New business from CSV
            business = build_new_business(row)
            business = apply_overrides(business, row, available_columns)
            stats["new"] += 1

        output.append(business)

    # Sort by id for deterministic output
    output.sort(key=lambda b: b["id"])

    # Print summary
    print()
    print("=" * 50)
    print("SUMMARY")
    print("=" * 50)
    print(f"  CSV rows processed: {len(rows)}")
    print(f"  Kept:               {stats['kept']}")
    print(f"  Skipped:            {stats['skipped']}")
    print(f"  Updated (existing): {stats['updated']}")
    print(f"  New (created):      {stats['new']}")
    print(f"  Output total:       {len(output)}")
    print()

    if args.dry_run:
        print("[DRY RUN] No file written.")
        if output:
            print(f"\nFirst kept business: {output[0]['name']} ({output[0]['id']})")
    else:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"Wrote {len(output)} businesses to {args.json}")


if __name__ == "__main__":
    main()
