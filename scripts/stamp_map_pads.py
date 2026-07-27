#!/usr/bin/env python3
"""Stamp exactly five locked pin pads onto pad-free campaign maps.

Use when image generation keeps inventing a 6th circular platform.

  python3 scripts/stamp_map_pads.py \\
    --src /path/to/map_nopads.png \\
    --dst assets/images/maps/map_ch_mistfen_marshes_a1.png
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# Must match Master Prompts locked layout (boss at 0.28 clears header/notch).
PADS = [
    (0.48, 0.88),
    (0.58, 0.72),
    (0.42, 0.56),
    (0.56, 0.38),
    (0.50, 0.28),
]


def draw_pad(diameter: int) -> Image.Image:
    img = Image.new("RGBA", (diameter, diameter), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = 2
    d.ellipse(
        (m, m, diameter - 1 - m, diameter - 1 - m),
        fill=(90, 95, 88, 230),
    )
    d.ellipse(
        (m, m, diameter - 1 - m, diameter - 1 - m),
        outline=(198, 160, 70, 255),
        width=max(3, diameter // 28),
    )
    inset = max(4, diameter // 12)
    d.ellipse(
        (
            m + inset,
            m + inset,
            diameter - 1 - m - inset,
            diameter - 1 - m - inset,
        ),
        outline=(60, 55, 45, 180),
        width=2,
    )
    return img


def stamp(src: Path, dst: Path) -> None:
    base = Image.open(src).convert("RGBA")
    w, h = base.size
    target = int(w * 0.10)
    sprite = draw_pad(160).resize((target, target), Image.Resampling.LANCZOS)
    shadow = Image.new("RGBA", sprite.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((4, 6, target - 2, target - 1), fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4))
    for x, y in PADS:
        cx, cy = int(x * w), int(y * h)
        tl = (cx - target // 2, cy - target // 2)
        base.alpha_composite(shadow, tl)
        base.alpha_composite(sprite, tl)
    dst.parent.mkdir(parents=True, exist_ok=True)
    base.convert("RGB").save(dst, "PNG", optimize=True)
    print(f"wrote {dst} ({dst.stat().st_size} bytes)")


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--src", type=Path, required=True)
    p.add_argument("--dst", type=Path, required=True)
    args = p.parse_args()
    stamp(args.src, args.dst)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
