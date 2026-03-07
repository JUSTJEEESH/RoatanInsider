#!/usr/bin/env python3
"""
sync_csv_to_json.py — Syncs businesses_curation.csv → businesses.json

WORKFLOW:
  1. Open businesses_curation.csv in Excel/Google Sheets/Numbers
  2. Make your changes (rename, change status, toggle featured, add notes, etc.)
  3. Save the CSV
  4. Run: python3 sync_csv_to_json.py
  5. Review the summary of changes
  6. Commit: git add . && git commit -m "Updated business listings"

WHAT THE CSV CONTROLS:
  - Name             → renames the business in the app
  - Category         → changes the category
  - Subcategory      → changes the subcategory
  - Area             → changes the area
  - Price Range      → changes price ($ $$ $$$ $$$$)
  - Status           → "active", "paused", or "closed" (closed = hidden from app)
  - KEEP?            → "no" removes the business entirely from the JSON
  - FEATURED?        → "yes" makes it appear in Featured sections
  - INSIDER PICK?    → "yes" makes it appear in Insider Picks
  - BEST OF?         → "yes" marks it as Best Of
  - NOTES            → your personal notes (not synced to app, just for tracking)
  - NEEDS REVIEW?    → flag businesses you need to verify in person
  - VERIFIED DATE    → date you last confirmed this business is correct
  - NEW NAME         → if the business changed names, put the new name here
                        (the script will update both Name column and the JSON)

WHAT THE CSV DOES NOT CONTROL (edit these in businesses.json directly or ask Claude):
  - Description, Insider Tip, GPS coordinates, hours, phone/whatsapp/email,
    website, facebook, instagram, features, images
"""

import csv
import json
import os
import sys
from datetime import datetime
from copy import deepcopy

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(SCRIPT_DIR, "businesses_curation.csv")
JSON_PATH = os.path.join(SCRIPT_DIR, "RoatanInsider", "Data", "businesses.json")
BACKUP_DIR = os.path.join(SCRIPT_DIR, ".backups")

PRICE_MAP = {"$": 1, "$$": 2, "$$$": 3, "$$$$": 4}
PRICE_REVERSE = {1: "$", 2: "$$", 3: "$$$", 4: "$$$$"}

AREA_DISPLAY_TO_KEY = {
    "West Bay": "west_bay",
    "West End": "west_end",
    "Sandy Bay": "sandy_bay",
    "Coxen Hole": "coxen_hole",
    "Flowers Bay": "flowers_bay",
    "French Harbour": "french_harbour",
    "Oak Ridge": "oak_ridge",
    "Punta Gorda": "punta_gorda",
    "Port Royal": "port_royal",
    "Camp Bay": "camp_bay",
    "Dixon Cove": "dixon_cove",
    "Palmetto Bay": "palmetto_bay",
    "Milton Bight": "milton_bight",
    "Johnson Bight": "johnson_bight",
}

# Also allow the raw key values
for v in list(AREA_DISPLAY_TO_KEY.values()):
    AREA_DISPLAY_TO_KEY[v] = v


def load_json():
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(data):
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def backup_json():
    os.makedirs(BACKUP_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(BACKUP_DIR, f"businesses_{timestamp}.json")
    with open(JSON_PATH, "r", encoding="utf-8") as src:
        with open(backup_path, "w", encoding="utf-8") as dst:
            dst.write(src.read())
    return backup_path


def load_csv():
    rows = []
    with open(CSV_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def slugify(name):
    import re
    slug = name.lower().strip()
    slug = re.sub(r"[''']", "", slug)
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    slug = slug.strip("-")
    return slug


def sync():
    print("=" * 60)
    print("  Roatan Insider — CSV → JSON Sync")
    print("=" * 60)
    print()

    # Load data
    businesses = load_json()
    csv_rows = load_csv()

    # Index businesses by ID
    biz_by_id = {b["id"]: b for b in businesses}

    changes = []
    removed = []
    warnings = []

    for row in csv_rows:
        bid = row.get("ID", "").strip()
        if not bid:
            continue

        if bid not in biz_by_id:
            warnings.append(f"  CSV has ID '{bid}' ({row.get('Name', '?')}) but it's not in the JSON — skipping")
            continue

        biz = biz_by_id[bid]
        row_changes = []

        # Handle NEW NAME column (rename)
        new_name = row.get("NEW NAME", "").strip()
        if new_name and new_name != biz["name"]:
            row_changes.append(f"  name: '{biz['name']}' → '{new_name}'")
            biz["name"] = new_name
            biz["slug"] = slugify(new_name)

        # Handle Name column (direct rename if no NEW NAME)
        csv_name = row.get("Name", "").strip()
        if not new_name and csv_name and csv_name != biz["name"]:
            row_changes.append(f"  name: '{biz['name']}' → '{csv_name}'")
            biz["name"] = csv_name
            biz["slug"] = slugify(csv_name)

        # Category
        csv_cat = row.get("Category", "").strip().lower()
        if csv_cat and csv_cat != biz["category"]:
            row_changes.append(f"  category: '{biz['category']}' → '{csv_cat}'")
            biz["category"] = csv_cat

        # Subcategory
        csv_sub = row.get("Subcategory", "").strip()
        if csv_sub and csv_sub != biz["subcategory"]:
            row_changes.append(f"  subcategory: '{biz['subcategory']}' → '{csv_sub}'")
            biz["subcategory"] = csv_sub

        # Area
        csv_area = row.get("Area", "").strip()
        if csv_area:
            area_key = AREA_DISPLAY_TO_KEY.get(csv_area, csv_area)
            if area_key != biz["area"]:
                row_changes.append(f"  area: '{biz['area']}' → '{area_key}'")
                biz["area"] = area_key

        # Price Range
        csv_price = row.get("Price Range", "").strip()
        if csv_price and csv_price in PRICE_MAP:
            new_price = PRICE_MAP[csv_price]
            if new_price != biz["priceRange"]:
                row_changes.append(f"  priceRange: {PRICE_REVERSE[biz['priceRange']]} → {csv_price}")
                biz["priceRange"] = new_price

        # Status
        csv_status = row.get("Status", "").strip().lower()
        if csv_status and csv_status != biz["status"]:
            row_changes.append(f"  status: '{biz['status']}' → '{csv_status}'")
            biz["status"] = csv_status

        # Featured
        csv_featured = row.get("FEATURED? (yes/no)", "").strip().lower()
        if csv_featured in ("yes", "no"):
            new_val = csv_featured == "yes"
            if new_val != biz.get("isFeatured", False):
                row_changes.append(f"  isFeatured: {biz.get('isFeatured', False)} → {new_val}")
                biz["isFeatured"] = new_val

        # Insider Pick
        csv_insider = row.get("INSIDER PICK? (yes/no)", "").strip().lower()
        if csv_insider in ("yes", "no"):
            new_val = csv_insider == "yes"
            if new_val != biz.get("isInsiderPick", False):
                row_changes.append(f"  isInsiderPick: {biz.get('isInsiderPick', False)} → {new_val}")
                biz["isInsiderPick"] = new_val

        # Best Of
        csv_bestof = row.get("BEST OF? (yes/no)", "").strip().lower()
        if csv_bestof in ("yes", "no"):
            new_val = csv_bestof == "yes"
            if new_val != biz.get("isBestOf", False):
                row_changes.append(f"  isBestOf: {biz.get('isBestOf', False)} → {new_val}")
                biz["isBestOf"] = new_val

        # KEEP? — remove from JSON if "no"
        csv_keep = row.get("KEEP? (yes/no)", "").strip().lower()
        if csv_keep == "no":
            removed.append(f"  {bid}: {biz['name']} (marked KEEP=no)")

        if row_changes:
            changes.append(f"\n  [{bid}] {biz['name']}:")
            changes.extend(row_changes)

    # Remove businesses marked as KEEP=no
    if removed:
        remove_ids = set()
        for row in csv_rows:
            if row.get("KEEP? (yes/no)", "").strip().lower() == "no":
                remove_ids.add(row["ID"].strip())
        businesses = [b for b in businesses if b["id"] not in remove_ids]

    # Print summary
    if not changes and not removed and not warnings:
        print("  No changes detected. CSV and JSON are in sync.")
        print()
        return

    if changes:
        print(f"  CHANGES ({len([c for c in changes if c.startswith(chr(10))])} businesses updated):")
        for c in changes:
            print(c)
        print()

    if removed:
        print(f"  REMOVED ({len(removed)} businesses):")
        for r in removed:
            print(r)
        print()

    if warnings:
        print(f"  WARNINGS:")
        for w in warnings:
            print(w)
        print()

    # Backup and save
    backup_path = backup_json()
    print(f"  Backup saved: {os.path.basename(backup_path)}")

    save_json(businesses)
    print(f"  businesses.json updated ({len(businesses)} businesses)")
    print()
    print("  Next steps:")
    print("    1. Review changes in the app or JSON")
    print("    2. git add . && git commit -m 'Updated business listings'")
    print()


if __name__ == "__main__":
    sync()
