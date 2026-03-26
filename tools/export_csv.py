#!/usr/bin/env python3
"""
Export businesses.json to a clean, editable CSV.

Opens in Google Sheets, Excel, or Numbers. Edit anything, then run
import_csv.py to convert back to JSON.

Usage:
    python3 tools/export_csv.py                          # writes businesses_edit.csv
    python3 tools/export_csv.py -o my_file.csv           # custom output path
"""

import csv
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
JSON_PATH = os.path.join(PROJECT_ROOT, "RoatanInsider", "Data", "businesses.json")
DEFAULT_CSV = os.path.join(PROJECT_ROOT, "businesses_edit.csv")

# Reverse maps for display
AREA_DISPLAY = {
    "west_bay": "West Bay",
    "west_end": "West End",
    "sandy_bay": "Sandy Bay",
    "coxen_hole": "Coxen Hole",
    "flowers_bay": "Flowers Bay",
    "french_harbour": "French Harbour",
    "oak_ridge": "Oak Ridge",
    "punta_gorda": "Punta Gorda",
    "port_royal": "Port Royal",
    "camp_bay": "Camp Bay",
    "dixon_cove": "Dixon Cove",
    "palmetto_bay": "Palmetto Bay",
    "milton_bight": "Milton Bight",
    "johnson_bight": "Johnson Bight",
}

CATEGORY_DISPLAY = {
    "eat": "Eat",
    "drink": "Drink",
    "dive": "Dive",
    "tours": "Tours",
    "shop": "Shop",
    "stay": "Stay",
    "rentals": "Rentals",
    "transport": "Transport",
    "beaches": "Beaches",
    "nightlife": "Nightlife",
}

COLUMNS = [
    # Identity
    "ID", "Name", "Slug", "Status",
    # Categorization
    "Category", "Subcategory", "Area", "Price Range",
    # Flags
    "Featured", "Insider Pick", "Best Of", "Verified",
    # Content
    "Description", "Insider Tip", "Address Description", "Hours Text",
    # Contact
    "Phone", "WhatsApp", "Email", "Website", "Facebook", "Instagram",
    # Location
    "Latitude", "Longitude",
    # Ratings
    "Rating", "Review Count",
    # Lists (comma-separated)
    "Features", "Collections", "Images",
    # Multi-category (format: category:subcategory | category:subcategory)
    "Additional Categories",
    # Multi-location (format: area:lat:lon:address | ...)
    "Additional Locations",
    # Menu
    "Menu Images",
]


def price_to_dollars(n):
    return "$" * n if n else "$"


def format_additional_cats(cats):
    if not cats:
        return ""
    parts = []
    for c in cats:
        cat = c.get("category", "")
        sub = c.get("subcategory", "")
        parts.append(f"{cat}:{sub}")
    return " | ".join(parts)


def format_additional_locs(locs):
    if not locs:
        return ""
    parts = []
    for loc in locs:
        area = loc.get("area", "")
        lat = loc.get("latitude", "")
        lon = loc.get("longitude", "")
        addr = loc.get("addressDescription", "")
        parts.append(f"{area}:{lat}:{lon}:{addr}")
    return " | ".join(parts)


def business_to_row(b):
    return {
        "ID": b.get("id", ""),
        "Name": b.get("name", ""),
        "Slug": b.get("slug", ""),
        "Status": b.get("status", "active"),
        "Category": CATEGORY_DISPLAY.get(b.get("category", ""), b.get("category", "")),
        "Subcategory": b.get("subcategory", ""),
        "Area": AREA_DISPLAY.get(b.get("area", ""), b.get("area", "")),
        "Price Range": price_to_dollars(b.get("priceRange", 1)),
        "Featured": "yes" if b.get("isFeatured") else "no",
        "Insider Pick": "yes" if b.get("isInsiderPick") else "no",
        "Best Of": "yes" if b.get("isBestOf") else "no",
        "Verified": "yes" if b.get("isVerified") else "no",
        "Description": b.get("description", ""),
        "Insider Tip": b.get("insiderTip") or "",
        "Address Description": b.get("addressDescription", ""),
        "Hours Text": b.get("hoursText") or "",
        "Phone": b.get("phone") or "",
        "WhatsApp": b.get("whatsapp") or "",
        "Email": b.get("email") or "",
        "Website": b.get("website") or "",
        "Facebook": b.get("facebook") or "",
        "Instagram": b.get("instagram") or "",
        "Latitude": b.get("latitude", ""),
        "Longitude": b.get("longitude", ""),
        "Rating": b.get("rating") or "",
        "Review Count": b.get("reviewCount") or "",
        "Features": ", ".join(b.get("features", [])),
        "Collections": ", ".join(b.get("collections", [])),
        "Images": ", ".join(b.get("images", [])),
        "Additional Categories": format_additional_cats(b.get("additionalCategories", [])),
        "Additional Locations": format_additional_locs(b.get("additionalLocations", [])),
        "Menu Images": ", ".join(b.get("menuImages", []) or []),
    }


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Export businesses.json to editable CSV")
    parser.add_argument("-o", "--output", default=DEFAULT_CSV, help="Output CSV path")
    parser.add_argument("--json", default=JSON_PATH, help="Input JSON path")
    args = parser.parse_args()

    with open(args.json, "r", encoding="utf-8") as f:
        businesses = json.load(f)

    businesses.sort(key=lambda b: b.get("id", ""))

    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS)
        writer.writeheader()
        for b in businesses:
            writer.writerow(business_to_row(b))

    print(f"✅ Exported {len(businesses)} businesses to {args.output}")
    print(f"   Open in Google Sheets, Excel, or Numbers to edit.")
    print(f"   When done, run: python3 tools/import_csv.py")


if __name__ == "__main__":
    main()
