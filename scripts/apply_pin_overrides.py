#!/usr/bin/env python3
"""Apply manually edited pin coords into campaign level JSON files.

Workflow:
  1. In-app: pin-edit mode → drag pins → Export all (copies JSON)
  2. Paste clipboard into tools/pin_overrides.json
  3. Run: python3 scripts/apply_pin_overrides.py

Input shape:
{
  "schemaVersion": 1,
  "pins": {
    "ch_skybridge_n01": { "mapX": 0.480, "mapY": 0.880 },
    ...
  }
}
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OVERRIDES = ROOT / "tools" / "pin_overrides.json"
LEVELS = ROOT / "assets" / "levels"
INDEX = LEVELS / "campaign_index.json"


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else OVERRIDES
    if not src.exists():
        print(f"Missing {src}")
        print("Export pins from the app, paste into tools/pin_overrides.json")
        return 1

    data = json.loads(src.read_text())
    pins = data.get("pins") or data
    if not isinstance(pins, dict) or not pins:
        print("No pins in overrides file")
        return 1

    index = json.loads(INDEX.read_text())
    assets = [c["asset"] for c in index.get("chapters", [])]
    updated_nodes = 0
    touched_files = 0

    for asset in assets:
        path = ROOT / asset
        chapter = json.loads(path.read_text())
        changed = False
        for act in chapter.get("acts", []):
            for node in act.get("nodes", []):
                nid = node.get("id")
                if nid not in pins:
                    continue
                p = pins[nid]
                mx = float(p["mapX"])
                my = float(p["mapY"])
                if node.get("mapX") != mx or node.get("mapY") != my:
                    node["mapX"] = mx
                    node["mapY"] = my
                    changed = True
                    updated_nodes += 1
        if changed:
            path.write_text(json.dumps(chapter, indent=2) + "\n")
            touched_files += 1
            print(f"updated {asset}")

    print(f"done: {updated_nodes} nodes in {touched_files} files")
    leftover = set(pins) - {
        n["id"]
        for asset in assets
        for act in json.loads((ROOT / asset).read_text()).get("acts", [])
        for n in act.get("nodes", [])
    }
    # Recompute leftover properly
    all_ids = set()
    for asset in assets:
        ch = json.loads((ROOT / asset).read_text())
        for act in ch.get("acts", []):
            for n in act.get("nodes", []):
                all_ids.add(n["id"])
    missing = [k for k in pins if k not in all_ids]
    if missing:
        print(f"warning: unknown node ids: {missing[:8]}{'…' if len(missing)>8 else ''}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
