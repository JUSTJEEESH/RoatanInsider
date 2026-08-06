#!/usr/bin/env python3
"""Check which businesses actually have a photo in Supabase.

All 94 records list `business_placeholder` as their image, so every one of
them resolves at runtime by slug: the app asks for
`<bucket>/<slug>.jpg` and quietly falls back to a category placeholder if
that 404s. That fallback is silent — nothing anywhere reports a miss — so a
business whose slug doesn't match its photo simply looks unfinished forever,
and nobody finds out.

This asks the bucket directly, once per business, and prints the misses.

    python3 tools/audit_photos.py
    python3 tools/audit_photos.py --json misses.json

Read-only. It fetches headers only, so it downloads no image data.
"""

import argparse
import json
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

BUCKET = "https://vbxmmslzanixvqswtnnv.supabase.co/storage/v1/object/public/business-photos/"
DEFAULT_DATA = os.path.join(os.path.dirname(__file__), "..", "RoatanInsider", "Data", "businesses.json")
TIMEOUT = 15


def photo_url(business):
    """Mirror BusinessImageView.supabaseURL exactly."""
    images = business.get("images") or []
    name = images[0] if images else ""
    if "." in name and name != "business_placeholder":
        return BUCKET + name
    return BUCKET + business["slug"] + ".jpg"


def exists(url):
    request = Request(url, method="HEAD")
    try:
        with urlopen(request, timeout=TIMEOUT) as response:
            return response.status == 200, response.status
    except HTTPError as error:
        return False, error.code
    except URLError as error:
        return False, str(error.reason)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data", default=DEFAULT_DATA, help="Path to businesses.json")
    parser.add_argument("--json", dest="json_out", help="Write the misses to this file")
    parser.add_argument("--workers", type=int, default=8)
    args = parser.parse_args()

    with open(args.data) as handle:
        data = json.load(handle)
    businesses = data if isinstance(data, list) else data.get("businesses", data)
    active = [b for b in businesses if b.get("status") == "active"]

    print(f"Checking {len(active)} active businesses against {BUCKET}\n")

    def check(business):
        found, status = exists(photo_url(business))
        return business, found, status

    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        results = list(pool.map(check, active))

    misses = [(b, status) for b, found, status in results if not found]
    hits = len(results) - len(misses)

    # If nothing at all resolved and every failure looks the same, the bucket
    # is unreachable — a proxy, a VPN, no signal. Reporting that as "90 photos
    # missing" would send someone re-uploading a library that's already there.
    if hits == 0 and misses:
        statuses = {status for _, status in misses}
        if len(statuses) == 1 and not isinstance(next(iter(statuses)), int):
            print(f"Could not reach the bucket at all: {next(iter(statuses))}")
            print("Every request failed the same way, so this says nothing about")
            print("the photos. Check your connection and run it again.")
            return 2

    for business, status in sorted(misses, key=lambda pair: pair[0]["name"]):
        print(f"  MISSING  {business['name']:<38} {business['slug']}.jpg   [{status}]")

    print(f"\n{hits}/{len(results)} have a photo.")
    if misses:
        print(f"{len(misses)} fall back to the category placeholder.")
        print("Fix by uploading <slug>.jpg to the bucket, or by putting the real")
        print("filename in the Images column of the CSV.")
    else:
        print("Every active business resolves to a real photo.")

    if args.json_out:
        with open(args.json_out, "w") as handle:
            json.dump(
                [{"slug": b["slug"], "name": b["name"], "status": s} for b, s in misses],
                handle,
                indent=2,
            )
        print(f"\nWrote {args.json_out}")

    return 1 if misses else 0


if __name__ == "__main__":
    sys.exit(main())
