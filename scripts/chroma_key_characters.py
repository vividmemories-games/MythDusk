#!/usr/bin/env python3
"""Chroma-key legacy #123A44 character masters to transparent source PNGs.

Always re-processes from assets/_opaque_bak/ (seeded on first run).
Writes reviewed sources under art_sources/runtime_png/; run
optimize_runtime_assets.py afterward to refresh the bundled WebP files.
Uses corner flood-fill for the flat teal background, then strips bright fringe.

Usage:
  python3 scripts/chroma_key_characters.py
"""

from __future__ import annotations

import math
import shutil
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

PROJECT_ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = PROJECT_ROOT / "assets"
BAK = ASSET_ROOT / "_opaque_bak"
OUTPUT_ROOT = PROJECT_ROOT / "art_sources" / "runtime_png"
KEY = (0x12, 0x3A, 0x44)
HARD = 38.0


def _dist(rgb: tuple[int, int, int]) -> float:
    return math.sqrt(sum((a - b) ** 2 for a, b in zip(rgb[:3], KEY)))


def _luma(r: int, g: int, b: int) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def process(path: Path, bak_path: Path) -> tuple[int, tuple[int, int]]:
    bak_path.parent.mkdir(parents=True, exist_ok=True)
    if not bak_path.exists():
        shutil.copy2(path, bak_path)

    img = Image.open(bak_path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    touched = 0

    bg = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()
    seeds = [
        (0, 0),
        (w - 1, 0),
        (0, h - 1),
        (w - 1, h - 1),
        (w // 2, 0),
        (0, h // 2),
        (w - 1, h // 2),
        (w // 2, h - 1),
    ]
    for sx, sy in seeds:
        bg[sy][sx] = True
        q.append((sx, sy))

    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny][nx]:
                r, g, b, _ = pixels[nx, ny]
                if _dist((r, g, b)) <= HARD + 8:
                    bg[ny][nx] = True
                    q.append((nx, ny))

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if bg[y][x]:
                pixels[x, y] = (r, g, b, 0)
                touched += 1
            else:
                d = _dist((r, g, b))
                if d <= HARD:
                    pixels[x, y] = (r, g, b, 0)
                    touched += 1
                elif d < HARD + 22:
                    t = (d - HARD) / 22.0
                    pixels[x, y] = (r, g, b, int(255 * t * t))
                    touched += 1

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a == 0 or a == 255:
                continue
            lum = _luma(r, g, b)
            if a < 180 and lum > 170:
                pixels[x, y] = (r, g, b, 0)
                touched += 1
            elif a < 60:
                pixels[x, y] = (r, g, b, 0)
                touched += 1

    alpha = img.getchannel("A")
    eroded = alpha.filter(ImageFilter.MinFilter(3))
    a_pix = alpha.load()
    e_pix = eroded.load()
    for y in range(h):
        for x in range(w):
            if 0 < a_pix[x, y] < 200 and e_pix[x, y] == 0:
                r, g, b, _ = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)
                touched += 1

    bbox = img.getbbox()
    if bbox:
        pad = max(6, int(min(w, h) * 0.015))
        l, t, r, b = bbox
        img = img.crop(
            (
                max(0, l - pad),
                max(0, t - pad),
                min(w, r + pad),
                min(h, b + pad),
            )
        )
    img.save(path, "PNG")
    return touched, img.size


def main() -> None:
    targets = (
        sorted((BAK / "heroes").glob("hero_*.png"))
        + sorted((BAK / "enemies").glob("enemy_*.png"))
        + sorted((BAK / "enemies" / "bosses").glob("boss_*.png"))
    )
    print(f"Processing {len(targets)} files from bak…")
    for bak_path in targets:
        rel = bak_path.relative_to(BAK)
        path = OUTPUT_ROOT / rel
        touched, size = process(path, bak_path)
        print(f"  {rel}: touched≈{touched} → {size[0]}x{size[1]}")
    print("done; run optimize_runtime_assets.py --apply to refresh WebP")


if __name__ == "__main__":
    main()
