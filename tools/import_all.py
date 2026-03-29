#!/usr/bin/env python3
"""
Import ALL edited CSV files back into JSON.

Reads:
  - businesses_edit.csv      → businesses.json
  - areas_edit.csv           → areas.json
  - essentials_edit.csv      → essentials.json
  - ask_a_local_edit.csv     → ask-a-local.json
  - cruise_mahogany_edit.csv → cruise-mahogany-bay.json
  - cruise_coxen_edit.csv    → cruise-coxen-hole.json

Updates manifest.json with bumped versions for changed files.

Usage:
    python3 tools/import_all.py                # convert all CSVs to JSON
    python3 tools/import_all.py --bump-version # also bump manifest for Supabase
    python3 tools/import_all.py --dry-run      # preview without writing
"""

import argparse
import csv
import json
import os
import sys
from datetime import datetime, timezone

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
DATA_DIR = os.path.join(PROJECT_ROOT, "RoatanInsider", "Data")
GUIDES_DIR = os.path.join(DATA_DIR, "guides")
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "manifest.json")


def read_csv(filename):
    """Read a CSV file from the project root, return list of dicts."""
    path = os.path.join(PROJECT_ROOT, filename)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def val(row, key):
    v = row.get(key, "")
    return v.strip() if v else ""


def import_businesses(dry_run):
    """Delegate to existing import_csv.py."""
    if dry_run:
        os.system(f"python3 {os.path.join(SCRIPT_DIR, 'import_csv.py')} --dry-run")
    else:
        os.system(f"python3 {os.path.join(SCRIPT_DIR, 'import_csv.py')}")
    return True


def import_areas(dry_run):
    rows = read_csv("areas_edit.csv")
    if rows is None:
        print("⏭️  areas_edit.csv not found — skipping")
        return False

    areas = []
    for row in rows:
        area_id = val(row, "ID")
        if not area_id:
            continue
        areas.append({
            "id": area_id,
            "area": area_id,
            "displayName": val(row, "Display Name"),
            "overview": val(row, "Overview"),
            "vibe": val(row, "Vibe"),
            "bestFor": val(row, "Best For"),
            "topPicks": [p.strip() for p in val(row, "Top Picks").split(",") if p.strip()],
            "gettingThere": val(row, "Getting There"),
        })

    print(f"  Areas: {len(areas)} entries")
    if not dry_run:
        output = os.path.join(DATA_DIR, "areas.json")
        with open(output, "w", encoding="utf-8") as f:
            json.dump(areas, f, indent=2, ensure_ascii=False)
            f.write("\n")
    return True


def import_essentials(dry_run):
    rows = read_csv("essentials_edit.csv")
    if rows is None:
        print("⏭️  essentials_edit.csv not found — skipping")
        return False

    topics = []
    for row in rows:
        tid = val(row, "ID")
        if not tid:
            continue
        tips_str = val(row, "Tips")
        tips = [t.strip() for t in tips_str.split("|") if t.strip()] if tips_str else []
        topics.append({
            "id": tid,
            "title": val(row, "Title"),
            "icon": val(row, "Icon"),
            "content": val(row, "Content"),
            "tips": tips,
        })

    print(f"  Essentials: {len(topics)} topics")
    if not dry_run:
        output = os.path.join(GUIDES_DIR, "essentials.json")
        with open(output, "w", encoding="utf-8") as f:
            json.dump({"topics": topics}, f, indent=2, ensure_ascii=False)
            f.write("\n")
    return True


def import_ask_a_local(dry_run):
    rows = read_csv("ask_a_local_edit.csv")
    if rows is None:
        print("⏭️  ask_a_local_edit.csv not found — skipping")
        return False

    questions = []
    for row in rows:
        qid = val(row, "ID")
        if not qid:
            continue
        questions.append({
            "id": qid,
            "question": val(row, "Question"),
            "answer": val(row, "Answer"),
        })

    print(f"  Ask a Local: {len(questions)} Q&As")
    if not dry_run:
        output = os.path.join(GUIDES_DIR, "ask-a-local.json")
        with open(output, "w", encoding="utf-8") as f:
            json.dump(questions, f, indent=2, ensure_ascii=False)
            f.write("\n")
    return True


def import_cruise_guide(csv_name, json_name, original_id, dry_run):
    rows = read_csv(csv_name)
    if rows is None:
        print(f"⏭️  {csv_name} not found — skipping")
        return False

    # Load existing to preserve structure
    json_path = os.path.join(GUIDES_DIR, json_name)
    existing = {}
    if os.path.exists(json_path):
        with open(json_path, "r", encoding="utf-8") as f:
            existing = json.load(f)

    guide = {
        "id": existing.get("id", original_id),
        "portName": existing.get("portName", ""),
        "portDescription": existing.get("portDescription", ""),
        "latitude": existing.get("latitude", 0),
        "longitude": existing.get("longitude", 0),
        "itineraries": [],
        "safetyTips": [],
        "returnReminder": existing.get("returnReminder", ""),
    }

    # Parse rows by section
    current_itinerary = None
    current_step = None

    for row in rows:
        section = val(row, "Section")
        field = val(row, "Field")
        value = val(row, "Value")

        if section == "PORT":
            if field == "Port Name":
                guide["portName"] = value
            elif field == "Description":
                guide["portDescription"] = value
            elif field == "Latitude":
                try: guide["latitude"] = float(value)
                except: pass
            elif field == "Longitude":
                try: guide["longitude"] = float(value)
                except: pass
            elif field == "Return Reminder":
                guide["returnReminder"] = value

        elif section == "SAFETY":
            if value:
                guide["safetyTips"].append(value)

        elif section.startswith("ITINERARY:"):
            itin_id = section.replace("ITINERARY:", "").strip()
            # Find or create itinerary
            current_itinerary = None
            for it in guide["itineraries"]:
                if it["id"] == itin_id:
                    current_itinerary = it
                    break
            if not current_itinerary:
                current_itinerary = {"id": itin_id, "duration": "", "title": "", "steps": []}
                guide["itineraries"].append(current_itinerary)

            if field == "Duration":
                current_itinerary["duration"] = value
            elif field == "Title":
                current_itinerary["title"] = value

        elif section.startswith("STEP:"):
            step_id = section.replace("STEP:", "").strip()
            # Find parent itinerary from step ID prefix
            parent = None
            for it in guide["itineraries"]:
                for s in it["steps"]:
                    if s["id"] == step_id:
                        parent = it
                        break
                if parent:
                    break

            # Find or create step
            if not parent and current_itinerary:
                parent = current_itinerary

            if parent:
                current_step = None
                for s in parent["steps"]:
                    if s["id"] == step_id:
                        current_step = s
                        break
                if not current_step:
                    current_step = {"id": step_id, "time": "", "title": "", "description": "", "estimatedCost": None, "tip": None}
                    parent["steps"].append(current_step)

                if field == "Time":
                    current_step["time"] = value
                elif field == "Title":
                    current_step["title"] = value
                elif field == "Description":
                    current_step["description"] = value
                elif field == "Estimated Cost":
                    current_step["estimatedCost"] = value or None
                elif field == "Tip":
                    current_step["tip"] = value or None

    itin_count = len(guide["itineraries"])
    step_count = sum(len(it["steps"]) for it in guide["itineraries"])
    print(f"  {guide['portName']}: {itin_count} itineraries, {step_count} steps")

    if not dry_run:
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(guide, f, indent=2, ensure_ascii=False)
            f.write("\n")
    return True


def main():
    parser = argparse.ArgumentParser(description="Import all CSV files back to JSON")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    parser.add_argument("--bump-version", action="store_true", help="Bump manifest versions")
    args = parser.parse_args()

    print()
    print("=" * 50)
    print("IMPORTING ALL CONTENT FROM CSV")
    print("=" * 50)
    print()

    changed = {}

    # Businesses (uses existing import_csv.py)
    biz_csv = os.path.join(PROJECT_ROOT, "businesses_edit.csv")
    if os.path.exists(biz_csv):
        import_businesses(args.dry_run)
        changed["businesses"] = True
    else:
        print("⏭️  businesses_edit.csv not found — skipping")

    # All other content
    if import_areas(args.dry_run):
        changed["areas"] = True
    if import_essentials(args.dry_run):
        changed["essentials"] = True
    if import_ask_a_local(args.dry_run):
        changed["askALocal"] = True
    if import_cruise_guide("cruise_mahogany_edit.csv", "cruise-mahogany-bay.json", "cruise-mahogany-bay", args.dry_run):
        changed["cruiseMahoganyBay"] = True
    if import_cruise_guide("cruise_coxen_edit.csv", "cruise-coxen-hole.json", "cruise-coxen-hole", args.dry_run):
        changed["cruiseCoxenHole"] = True

    if args.dry_run:
        print("\n[DRY RUN] No files written.")
        return

    if args.bump_version and changed:
        # Load or create manifest
        manifest = {}
        if os.path.exists(MANIFEST_PATH):
            with open(MANIFEST_PATH, "r") as f:
                manifest = json.load(f)

        # Migrate old flat format to new format
        if "version" in manifest and "businesses" not in manifest:
            old_version = manifest.pop("version")
            manifest["businesses"] = {"version": old_version, "file": "businesses.json"}

        file_map = {
            "businesses": "businesses.json",
            "areas": "areas.json",
            "essentials": "essentials.json",
            "askALocal": "ask-a-local.json",
            "cruiseMahoganyBay": "cruise-mahogany-bay.json",
            "cruiseCoxenHole": "cruise-coxen-hole.json",
        }

        for key in changed:
            if key not in manifest or not isinstance(manifest.get(key), dict):
                manifest[key] = {"version": 0, "file": file_map.get(key, "")}
            manifest[key]["version"] = manifest[key].get("version", 0) + 1

        manifest["updatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

        with open(MANIFEST_PATH, "w") as f:
            json.dump(manifest, f, indent=2)
            f.write("\n")

        print()
        print("✅ Manifest updated:")
        for key in changed:
            v = manifest[key]["version"]
            print(f"   {key}: v{v} → {manifest[key]['file']}")

        print()
        print("Next steps:")
        print("  Upload these files to Supabase → app-data bucket:")
        print(f"  1. manifest.json (from {PROJECT_ROOT})")
        for key in changed:
            fname = file_map.get(key, "")
            if key == "businesses":
                print(f"  2. {fname} (from RoatanInsider/Data/)")
            elif key in ("areas",):
                print(f"  3. {fname} (from RoatanInsider/Data/)")
            else:
                print(f"  4. {fname} (from RoatanInsider/Data/guides/)")
    elif not args.bump_version:
        print()
        print("To push to the app, run again with --bump-version:")
        print("  python3 tools/import_all.py --bump-version")


if __name__ == "__main__":
    main()
