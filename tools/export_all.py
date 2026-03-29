#!/usr/bin/env python3
"""
Export ALL app content to editable CSV files.

Creates:
  - businesses_edit.csv      (business directory)
  - areas_edit.csv           (area guide content)
  - essentials_edit.csv      (island essentials topics)
  - ask_a_local_edit.csv     (Q&A content)
  - cruise_mahogany_edit.csv (Mahogany Bay cruise itineraries)
  - cruise_coxen_edit.csv    (Coxen Hole cruise itineraries)

Usage:
    python3 tools/export_all.py
"""

import csv
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(PROJECT_ROOT, "RoatanInsider", "Data")
GUIDES_DIR = os.path.join(DATA_DIR, "guides")


def export_businesses():
    """Export businesses.json — delegates to existing export_csv.py logic."""
    os.system(f"python3 {os.path.join(SCRIPT_DIR, 'export_csv.py')}")


def export_areas():
    path = os.path.join(DATA_DIR, "areas.json")
    if not os.path.exists(path):
        print(f"⚠️ {path} not found")
        return

    with open(path, "r", encoding="utf-8") as f:
        areas = json.load(f)

    output = os.path.join(PROJECT_ROOT, "areas_edit.csv")
    columns = ["ID", "Display Name", "Overview", "Vibe", "Best For", "Top Picks", "Getting There"]

    with open(output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for a in areas:
            writer.writerow({
                "ID": a.get("id", ""),
                "Display Name": a.get("displayName", ""),
                "Overview": a.get("overview", ""),
                "Vibe": a.get("vibe", ""),
                "Best For": a.get("bestFor", ""),
                "Top Picks": ", ".join(a.get("topPicks", [])),
                "Getting There": a.get("gettingThere", ""),
            })

    print(f"✅ Exported {len(areas)} areas to areas_edit.csv")


def export_essentials():
    path = os.path.join(GUIDES_DIR, "essentials.json")
    if not os.path.exists(path):
        print(f"⚠️ {path} not found")
        return

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    topics = data.get("topics", [])
    output = os.path.join(PROJECT_ROOT, "essentials_edit.csv")
    columns = ["ID", "Title", "Icon", "Content", "Tips"]

    with open(output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for t in topics:
            writer.writerow({
                "ID": t.get("id", ""),
                "Title": t.get("title", ""),
                "Icon": t.get("icon", ""),
                "Content": t.get("content", ""),
                "Tips": " | ".join(t.get("tips", [])),
            })

    print(f"✅ Exported {len(topics)} essentials topics to essentials_edit.csv")


def export_ask_a_local():
    path = os.path.join(GUIDES_DIR, "ask-a-local.json")
    if not os.path.exists(path):
        print(f"⚠️ {path} not found")
        return

    with open(path, "r", encoding="utf-8") as f:
        questions = json.load(f)

    output = os.path.join(PROJECT_ROOT, "ask_a_local_edit.csv")
    columns = ["ID", "Question", "Answer"]

    with open(output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for q in questions:
            writer.writerow({
                "ID": q.get("id", ""),
                "Question": q.get("question", ""),
                "Answer": q.get("answer", ""),
            })

    print(f"✅ Exported {len(questions)} Q&As to ask_a_local_edit.csv")


def export_cruise_guide(filename, output_name):
    path = os.path.join(GUIDES_DIR, filename)
    if not os.path.exists(path):
        print(f"⚠️ {path} not found")
        return

    with open(path, "r", encoding="utf-8") as f:
        guide = json.load(f)

    output = os.path.join(PROJECT_ROOT, output_name)
    columns = [
        "Section", "Field", "Value"
    ]

    rows = []

    # Port info
    rows.append({"Section": "PORT", "Field": "Port Name", "Value": guide.get("portName", "")})
    rows.append({"Section": "PORT", "Field": "Description", "Value": guide.get("portDescription", "")})
    rows.append({"Section": "PORT", "Field": "Latitude", "Value": str(guide.get("latitude", ""))})
    rows.append({"Section": "PORT", "Field": "Longitude", "Value": str(guide.get("longitude", ""))})
    rows.append({"Section": "PORT", "Field": "Return Reminder", "Value": guide.get("returnReminder", "")})

    # Safety tips
    for i, tip in enumerate(guide.get("safetyTips", [])):
        rows.append({"Section": "SAFETY", "Field": f"Tip {i+1}", "Value": tip})

    # Itineraries
    for itin in guide.get("itineraries", []):
        itin_id = itin.get("id", "")
        rows.append({"Section": f"ITINERARY: {itin_id}", "Field": "Duration", "Value": itin.get("duration", "")})
        rows.append({"Section": f"ITINERARY: {itin_id}", "Field": "Title", "Value": itin.get("title", "")})

        for step in itin.get("steps", []):
            step_id = step.get("id", "")
            rows.append({"Section": f"STEP: {step_id}", "Field": "Time", "Value": step.get("time", "")})
            rows.append({"Section": f"STEP: {step_id}", "Field": "Title", "Value": step.get("title", "")})
            rows.append({"Section": f"STEP: {step_id}", "Field": "Description", "Value": step.get("description", "")})
            rows.append({"Section": f"STEP: {step_id}", "Field": "Estimated Cost", "Value": step.get("estimatedCost", "") or ""})
            rows.append({"Section": f"STEP: {step_id}", "Field": "Tip", "Value": step.get("tip", "") or ""})

    with open(output, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)

    itin_count = len(guide.get("itineraries", []))
    print(f"✅ Exported {guide.get('portName', '')} cruise guide ({itin_count} itineraries) to {output_name}")


def main():
    print("=" * 50)
    print("EXPORTING ALL CONTENT TO CSV")
    print("=" * 50)
    print()

    export_businesses()
    export_areas()
    export_essentials()
    export_ask_a_local()
    export_cruise_guide("cruise-mahogany-bay.json", "cruise_mahogany_edit.csv")
    export_cruise_guide("cruise-coxen-hole.json", "cruise_coxen_edit.csv")

    print()
    print("All CSV files are in your RoatanInsider folder.")
    print("Edit them, then run: python3 tools/import_all.py --bump-version")


if __name__ == "__main__":
    main()
