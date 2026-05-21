#!/usr/bin/env python3
"""
One-off sweeper for businesses.json that applies the agreed voice rules:
  - cut empty superlatives (iconic, stunning, famous, legendary, top-rated,
    world-class, exquisite, refined, intimate)
  - cut tourism clichés (Instagram-worthy, hidden gem, intimate gem,
    'the perfect X', 'stuff of legend')
  - drop TripAdvisor / Voted-#X ranking claims (they decay)
  - keep all facts intact: dish names, prices, hours, dates, chef names

Run from repo root:
    python3 scripts/sweep_business_voice.py
"""
import json
import re
import sys
from pathlib import Path

SOURCE = Path("RoatanInsider/Data/businesses.json")

# Per-string rewrites — applied FIRST as substring replacements, before regex rules.
# Use these when a generic strip would leave a sentence fragment.
SPECIFIC_REWRITES: dict[str, str] = {
    "The banana pancakes are legendary.": "Order the banana pancakes.",
    "Bruschetta and lasagna are the stuff of Roatan legend.": "Bruschetta and lasagna are the standouts.",
    "The lobster ravioli and limoncello tiramisu are legendary.": "Don't skip the lobster ravioli or the limoncello tiramisu.",
    "The Sunday brunch is legendary. Worth every lempira.": "Don't skip the Sunday brunch.",
    "The Sunday brunch is legendary.": "The Sunday brunch is the standout.",
    "Buy a bag of beans to take home - Honduran coffee is world-class.": "Buy a bag of beans to take home.",
    "The driftwood lamps are stunning conversation pieces.": "Pick up one of the driftwood lamps as a souvenir.",
    "Sunset dinner on the second floor terrace is unforgettable.": "Reserve the second-floor terrace for sunset.",
    "The horseback ride on the beach is unforgettable.": "Take the horseback ride along the beach.",
    "Shore diving right off West Bay Beach is incredible for beginners.": "Shore diving right off West Bay Beach is great for beginners.",
    "Yes, the poutine in the Caribbean is actually amazing.": "Yes, the poutine in the Caribbean is actually good.",
}

# Each rule is (pattern, replacement). Order matters — earlier rules run first.
# All patterns are case-sensitive unless flagged with (?i).
RULES: list[tuple[str, str]] = [
    # -------- Sentence-leading hype adjectives + space --------
    # Allow optional leading whitespace so we still catch the word after an
    # upstream rule stripped its preceding sentence (e.g. 'Voted #1...').
    (r"^\s*Iconic\s+", ""),
    (r"^\s*Stunning\s+", ""),
    (r"^\s*Top-rated\s+", ""),
    (r"^\s*Refined\s+", ""),
    (r"^\s*Exquisite\s+", ""),
    (r"^\s*Legendary\s+", ""),
    (r"^\s*Famous\s+", ""),
    (r"\.\s+Iconic\s+", ". "),
    (r"\.\s+Stunning\s+", ". "),
    (r"\.\s+Top-rated\s+", ". "),
    (r"\.\s+Refined\s+", ". "),
    (r"\.\s+Exquisite\s+", ". "),
    (r"\.\s+Legendary\s+", ". "),
    (r"\.\s+Famous\s+", ". "),

    # -------- Other generic hype adjectives (only safe nominal patterns) --------
    (r"\bmagical (mangrove tunnels|mangroves|reefs)\b", r"\1"),
    (r"\bincredible (birdlife|reef|seafood|views|sunsets)\b", r"\1"),

    # -------- Specific common phrasings --------
    (r"\bBest Mexican food on Roatan\b", "Mexican food in West End"),
    (r"\bRoatan'?s most popular\b", "A popular"),
    (r"\bRoatan'?s go-to\b", "A go-to"),
    (r"\bRoatan'?s #1-ranked restaurant on TripAdvisor\b", ""),
    (r"\bWest Bay'?s #1-ranked restaurant on TripAdvisor", ""),
    (r"\bthe best sunset views on Roatan\b", "west-facing sunset views"),
    (r"\bbest sunset views\b", "west-facing sunset views"),
    (r"\bRoatan'?s most upscale hotel\b", "An upscale hotel"),

    # -------- Inline hype adjectives modifying nouns --------
    # Only when followed by a noun phrase — keep replacements conservative
    (r"\bfamous (Monkey La La cocktails|rice and beans|cinnamon rolls|jerk chicken|wine cellar)\b", r"\1"),
    (r"\blegendary ([A-Z][a-z]+ [A-Z][a-z]+( [A-Z][a-z]+)?)", r"\1"),  # "legendary Big Kahuna Burrito" → "Big Kahuna Burrito"
    (r"\blegendary (jerk chicken|cinnamon rolls|Sunday brunch|Thursday karaoke|south shore dive resort)\b", r"\1"),
    (r"\bstunning (sunset views|ocean views|conversation pieces|natural lagoon)\b", r"\1"),
    (r"\bIconic ([A-Z][a-z]+( [A-Z][a-z]+)?)", r"\1"),
    (r"\bexquisite (local cuisine|seafood|fish)\b", r"\1"),

    # -------- Cliché phrases --------
    (r" in an Instagram-worthy setting", ""),
    (r"\bInstagram-worthy ", ""),
    (r" the perfect healthy lunch break", " a healthy lunch break"),
    (r" the perfect island getaway", ""),
    (r" the perfect sunset spot", ""),
    (r"\bintimate gem\b", "spot"),
    (r"\s*A true hidden gem\.\s*", " "),
    (r"\bhidden gem\b", ""),

    # 'world-class' — drop the standalone word; specific 'is world-class' sentences are
    # handled by SPECIFIC_REWRITES above.
    (r"\bworld-class ", ""),
    (r"\bworld-class\b", ""),

    (r"\bmust-try\b", ""),
    (r" absolutely worth", " worth"),
    (r" Surprisingly reasonable", " Reasonable"),
    (r"\bsurprisingly reasonable\b", "reasonable"),
    (r"\bAbsolutely worth\b", "Worth"),
    (r"\bworth every minute of the wait\b", "worth the wait"),
    (r"\bworth every lempira\b", "worth it"),

    # 'pure island elegance' — drop including the leading em-dash, the orphan word before it,
    # and the trailing period.
    (r"\s*—\s*pure island elegance\.", "."),
    (r"\bpure island elegance\b", ""),

    # -------- Sentence patterns that often appear as filler --------
    (r"\bMary'?s Place \(voted Best Dive Site 2018\)", "Mary's Place"),
    (r"\s+Voted Best [^.]{1,40}\.", "."),
    # Match the WHOLE ranking sentence (including its trailing period + whitespace).
    (r"^Voted #\d+[^.]{0,40}\.\s*", ""),
    (r"\s+Voted #\d+[^.]{0,40}\.\s*", " "),
    (r"^[^.]{0,15}Ranked #\d+[^.]{0,60}TripAdvisor[^.]{0,30}\.\s*", ""),
    (r"\s+[^.]{0,15}Ranked #\d+[^.]{0,60}TripAdvisor[^.]{0,30}\.\s*", " "),
    (r"^\w+'?s #1-ranked restaurant on TripAdvisor\.\s*", ""),
    (r"\s+\w+'?s #1-ranked restaurant on TripAdvisor\.\s*", " "),

    # -------- Exclamation point clean-up --------
    # Replace ! at end of sentence with .
    (r"!(?=\s|$)", "."),

    # -------- Whitespace normalization (after deletions) --------
    (r"  +", " "),                # collapse double spaces
    (r"\s+,", ","),               # space-comma
    (r"\s+\.", "."),              # space-period
    (r"\.\s+\.", "."),            # period-space-period
    (r"\s*—\s*\.", "."),          # orphan em-dash before period
    (r"\s+—\s+([.,])", r"\1"),    # orphan em-dash before comma/period
    (r"^[\s.\-—]+", ""),          # strip leading whitespace/period/dash
    (r"\s+$", ""),                # trailing whitespace
]


def clean(text: str) -> str:
    if not text:
        return text
    out = text

    # First pass: literal substring rewrites for sentences that need a verb
    # to remain valid English after the strip.
    for old, new in SPECIFIC_REWRITES.items():
        out = out.replace(old, new)

    for pattern, repl in RULES:
        out = re.sub(pattern, repl, out)

    # Capitalize first letter if a deletion left it lowercase.
    if out and out[0].islower():
        out = out[0].upper() + out[1:]

    # Capitalize the first letter of any sentence that lost its leading
    # capitalized word (e.g. "Stunning sunset views" → " sunset views" → ". sunset views").
    out = re.sub(r"(\.\s+)([a-z])", lambda m: m.group(1) + m.group(2).upper(), out)

    return out


def main() -> int:
    if not SOURCE.exists():
        print(f"Missing {SOURCE}", file=sys.stderr)
        return 1

    raw = SOURCE.read_text(encoding="utf-8")
    data = json.loads(raw)

    diffs: list[tuple[str, str, str, str]] = []  # (name, field, before, after)

    for biz in data:
        for field in ("description", "insiderTip"):
            before = biz.get(field)
            if not before:
                continue
            after = clean(before)
            if after != before:
                diffs.append((biz.get("name", "?"), field, before, after))
                biz[field] = after

    SOURCE.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"Modified {len(diffs)} field(s) across {SOURCE.name}\n")
    for name, field, before, after in diffs:
        print(f"  {name} · {field}")
        print(f"    -  {before}")
        print(f"    +  {after}")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
