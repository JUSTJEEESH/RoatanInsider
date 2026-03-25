#!/usr/bin/env python3
"""
Convert businesses_curation.csv into businesses.json.

Reads the CSV curation file and the existing businesses.json, merges them
according to the KEEP/override/merge rules, and writes the updated JSON.

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
        return None
    key = area_str.strip().lower()
    if key in AREA_MAP:
        return AREA_MAP[key]
    if key.replace(" ", "_") in AREA_MAP.values():
        return key.replace(" ", "_")
    normalized = key.replace(" ", "_")
    for v in AREA_MAP.values():
        if v == normalized:
            return v
    return None


def normalize_category(cat_str):
    """Convert category display name to enum raw value."""
    if not cat_str:
        return None
    key = cat_str.strip().lower()
    if key in CATEGORY_MAP:
        return CATEGORY_MAP[key]
    for v in CATEGORY_MAP.values():
        if v == key:
            return v
    return None


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
        "category": normalize_category(get_csv_value(row, "Category")) or "eat",
        "subcategory": get_csv_value(row, "Subcategory") or "",
        "area": normalize_area(get_csv_value(row, "Area")) or "west_bay",
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
        "additionalCategories": [],
        "additionalLocations": [],
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
    collections = list(business.get("collections", []))
    for col_header, col_key in COLLECTION_COLUMNS.items():
        if col_header in available_columns:
            if is_yes(get_csv_value(row, col_header)):
                if col_key not in collections:
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
    elif "menuImages" not in business:
        business["menuImages"] = None

    # Additional categories (from CSV CATEGORY 2/3 columns)
    additional_cats = list(business.get("additionalCategories", []))
    for n in [2, 3]:
        cat_str = get_csv_value(row, f"CATEGORY {n}")
        sub_str = get_csv_value(row, f"SUBCATEGORY {n}")
        if cat_str:
            cat_val = normalize_category(cat_str)
            if cat_val and sub_str:
                entry = {"category": cat_val, "subcategory": sub_str}
                if entry not in additional_cats:
                    additional_cats.append(entry)
    business["additionalCategories"] = additional_cats

    # Additional locations (from CSV LOCATION 2 columns)
    additional_locs = list(business.get("additionalLocations", []))
    loc2_area = get_csv_value(row, "LOCATION 2 AREA")
    loc2_lat = get_csv_value(row, "LOCATION 2 LAT")
    loc2_lon = get_csv_value(row, "LOCATION 2 LON")
    loc2_addr = get_csv_value(row, "LOCATION 2 ADDRESS")
    if loc2_area and loc2_lat and loc2_lon:
        try:
            loc_entry = {
                "area": normalize_area(loc2_area) or loc2_area,
                "latitude": float(loc2_lat),
                "longitude": float(loc2_lon),
                "addressDescription": loc2_addr or "",
            }
            if loc_entry not in additional_locs:
                additional_locs.append(loc_entry)
        except ValueError:
            pass
    business["additionalLocations"] = additional_locs

    return business


def ensure_new_fields(business):
    """Ensure all required fields exist on every business."""
    if "collections" not in business:
        business["collections"] = []
    if "menuImages" not in business:
        business["menuImages"] = None
    if "additionalCategories" not in business:
        business["additionalCategories"] = []
    if "additionalLocations" not in business:
        business["additionalLocations"] = []
    return business


def merge_into_target(target, source_row, source_existing, available_columns):
    """
    Merge a source business into a target business.
    Adds the source's category/subcategory as an additional category,
    and merges features, collections, and contact info.
    """
    # Get source data (from existing JSON if available, otherwise from CSV)
    source_id = get_csv_value(source_row, "ID")
    source = dict(source_existing) if source_existing else {}

    # Add source's primary category as an additional category on the target
    src_cat = normalize_category(get_csv_value(source_row, "Category"))
    src_sub = get_csv_value(source_row, "Subcategory")
    if src_cat and src_sub:
        entry = {"category": src_cat, "subcategory": src_sub}
        if "additionalCategories" not in target:
            target["additionalCategories"] = []
        # Don't add if it matches the target's primary or is already there
        if not (target["category"] == src_cat and target["subcategory"] == src_sub):
            if entry not in target["additionalCategories"]:
                target["additionalCategories"].append(entry)

    # Also merge CATEGORY 2/3 from source row
    for n in [2, 3]:
        cat_str = get_csv_value(source_row, f"CATEGORY {n}")
        sub_str = get_csv_value(source_row, f"SUBCATEGORY {n}")
        if cat_str:
            cat_val = normalize_category(cat_str)
            if cat_val and sub_str:
                entry = {"category": cat_val, "subcategory": sub_str}
                if entry not in target["additionalCategories"]:
                    target["additionalCategories"].append(entry)

    # Merge features from source
    if source.get("features"):
        existing_features = set(target.get("features", []))
        for feat in source["features"]:
            if feat not in existing_features:
                target["features"].append(feat)

    # Merge collections from source
    if source.get("collections"):
        for col in source["collections"]:
            if col not in target.get("collections", []):
                target["collections"].append(col)

    # Merge contact info (fill in blanks)
    for field in ["phone", "whatsapp", "email", "website", "facebook", "instagram"]:
        if not target.get(field) and source.get(field):
            target[field] = source[field]

    # Merge rating (keep higher)
    if source.get("rating") and (not target.get("rating") or source["rating"] > target["rating"]):
        target["rating"] = source["rating"]
    if source.get("reviewCount") and (not target.get("reviewCount") or source["reviewCount"] > target["reviewCount"]):
        target["reviewCount"] = source["reviewCount"]

    return target


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

    # Build lookup of rows by ID
    rows_by_id = {}
    for row in rows:
        bid = get_csv_value(row, "ID")
        if bid:
            rows_by_id[bid] = row

    # Pass 1: identify merges and kept businesses
    merge_map = {}  # source_id -> target_id
    stats = {"kept": 0, "skipped": 0, "merged": 0, "new": 0, "updated": 0}

    for row in rows:
        bid = get_csv_value(row, "ID")
        if not bid:
            continue
        merge_target = get_csv_value(row, "MERGE INTO")
        if merge_target:
            merge_map[bid] = merge_target
            stats["merged"] += 1

    # Pass 2: build output
    output_map = {}  # id -> business dict

    for row in rows:
        bid = get_csv_value(row, "ID")
        if not bid:
            stats["skipped"] += 1
            continue

        # Skip rows that are being merged into another
        if bid in merge_map:
            continue

        keep_val = get_csv_value(row, "KEEP? (yes/no)")
        if not is_yes(keep_val):
            stats["skipped"] += 1
            continue

        stats["kept"] += 1

        if bid in existing:
            business = dict(existing[bid])
            business = ensure_new_fields(business)
            business = apply_overrides(business, row, available_columns)
            stats["updated"] += 1
        else:
            business = build_new_business(row)
            business = apply_overrides(business, row, available_columns)
            stats["new"] += 1

        output_map[bid] = business

    # Pass 3: apply merges
    for source_id, target_id in merge_map.items():
        if target_id not in output_map:
            print(f"  WARNING: merge target {target_id} not in output (skipped or missing). Source {source_id} ignored.")
            continue

        source_row = rows_by_id.get(source_id, {})
        source_existing = existing.get(source_id)
        output_map[target_id] = merge_into_target(
            output_map[target_id], source_row, source_existing, available_columns
        )
        print(f"  Merged {source_id} into {target_id}")

    output = list(output_map.values())
    output.sort(key=lambda b: b["id"])

    # Print summary
    print()
    print("=" * 50)
    print("SUMMARY")
    print("=" * 50)
    print(f"  CSV rows processed: {len(rows)}")
    print(f"  Kept:               {stats['kept']}")
    print(f"  Skipped:            {stats['skipped']}")
    print(f"  Merged into others: {stats['merged']}")
    print(f"  Updated (existing): {stats['updated']}")
    print(f"  New (created):      {stats['new']}")
    print(f"  Output total:       {len(output)}")
    print()

    if args.dry_run:
        print("[DRY RUN] No file written.")
        if output:
            print(f"\nFirst kept business: {output[0]['name']} ({output[0]['id']})")
            # Show any multi-category businesses
            multi = [b for b in output if b.get("additionalCategories")]
            if multi:
                print(f"\nMulti-category businesses: {len(multi)}")
                for b in multi:
                    cats = [f"{b['category']}/{b['subcategory']}"] + [
                        f"{c['category']}/{c['subcategory']}" for c in b["additionalCategories"]
                    ]
                    print(f"  {b['name']}: {', '.join(cats)}")
    else:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2, ensure_ascii=False)
            f.write("\n")
        print(f"Wrote {len(output)} businesses to {args.json}")


if __name__ == "__main__":
    main()
