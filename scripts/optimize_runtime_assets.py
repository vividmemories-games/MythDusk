#!/usr/bin/env python3
"""Convert large runtime PNG art to WebP and archive the source PNGs.

The archived PNGs stay available for future art edits under
`art_sources/runtime_png/`, which is not included in the Flutter bundle.

Run from anywhere:
  python3 scripts/optimize_runtime_assets.py --apply
"""

from __future__ import annotations

import argparse
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageStat, features


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ARCHIVE = ROOT / "art_sources" / "runtime_png"


@dataclass(frozen=True)
class AssetGroup:
    directory: str
    quality: int


@dataclass(frozen=True)
class ConversionJob:
    source: Path
    output: Path
    quality: int
    archive_after: bool


GROUPS = (
    AssetGroup("assets/images/maps", 82),
    AssetGroup("assets/images/backgrounds", 84),
    AssetGroup("assets/images/backgrounds/battle", 84),
    AssetGroup("assets/enemies", 90),
    AssetGroup("assets/enemies/bosses", 90),
    AssetGroup("assets/heroes", 92),
)

DEVELOPMENT_ONLY = (
    "assets/images/maps/map_ch_twilight_road_768x2048_bak.png",
)


def _format_bytes(value: int) -> str:
    return f"{value / (1024 * 1024):.1f} MiB"


def _convert(source: Path, output: Path, quality: int) -> tuple[int, int, float]:
    before = source.stat().st_size
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(f"{output.name}.tmp")

    try:
        with Image.open(source) as image:
            image.load()
            image.save(
                temporary,
                "WEBP",
                quality=quality,
                method=6,
                exact=True,
            )
            with Image.open(temporary) as decoded:
                decoded.load()
                if decoded.size != image.size:
                    raise RuntimeError(f"dimension mismatch for {source}")
                original_rgba = image.convert("RGBA")
                decoded_rgba = decoded.convert("RGBA")
                difference = ImageChops.difference(original_rgba, decoded_rgba)
                mean_channels = ImageStat.Stat(difference).mean
                mean_rgb_error = sum(mean_channels[:3]) / 3
                if mean_channels[3] != 0:
                    raise RuntimeError(f"alpha changed while converting {source}")
                if mean_rgb_error > 8:
                    raise RuntimeError(
                        f"visual error {mean_rgb_error:.2f} exceeds limit for {source}"
                    )
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)

    return before, output.stat().st_size, mean_rgb_error


def _archive_source(source: Path) -> None:
    archive = SOURCE_ARCHIVE / source.relative_to(ROOT)
    archive.parent.mkdir(parents=True, exist_ok=True)
    if archive.exists():
        raise FileExistsError(f"archive already exists: {archive}")
    shutil.move(source, archive)


def _move_development_only() -> None:
    destination_root = ROOT / "art_sources" / "development"
    for relative in DEVELOPMENT_ONLY:
        source = ROOT / relative
        if not source.exists():
            continue
        destination = destination_root / source.relative_to(ROOT)
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            raise FileExistsError(f"destination already exists: {destination}")
        shutil.move(source, destination)
        print(f"moved development-only {source.relative_to(ROOT)}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--apply",
        action="store_true",
        help="perform conversion; without this flag only prints the plan",
    )
    args = parser.parse_args()

    if not features.check("webp"):
        raise SystemExit("Pillow was built without WebP support")

    jobs: list[ConversionJob] = []
    development_only = {ROOT / path for path in DEVELOPMENT_ONLY}
    for group in GROUPS:
        runtime_directory = ROOT / group.directory
        archive_directory = SOURCE_ARCHIVE / group.directory
        archived = {
            path.name: path
            for path in sorted(archive_directory.glob("*.png"))
        }
        for source in sorted(runtime_directory.glob("*.png")):
            if source in development_only:
                continue
            if source.name in archived:
                raise RuntimeError(
                    f"duplicate runtime and archived source: {source.relative_to(ROOT)}"
                )
            jobs.append(
                ConversionJob(
                    source=source,
                    output=source.with_suffix(".webp"),
                    quality=group.quality,
                    archive_after=True,
                )
            )
        for source in archived.values():
            output = runtime_directory / source.with_suffix(".webp").name
            jobs.append(
                ConversionJob(
                    source=source,
                    output=output,
                    quality=group.quality,
                    archive_after=False,
                )
            )

    print(f"{len(jobs)} runtime PNG sources selected")
    if not args.apply:
        for job in jobs:
            action = "migrate" if job.archive_after else "regenerate"
            print(
                f"  q{job.quality} {action} "
                f"{job.source.relative_to(ROOT)} -> "
                f"{job.output.relative_to(ROOT)}"
            )
        print("dry run; pass --apply to convert")
        return

    total_before = 0
    total_after = 0
    for job in jobs:
        before, after, error = _convert(job.source, job.output, job.quality)
        if job.archive_after:
            _archive_source(job.source)
        total_before += before
        total_after += after
        print(
            f"  {job.source.relative_to(ROOT)}: "
            f"{before / 1024:.0f} -> {after / 1024:.0f} KiB "
            f"(mean RGB error {error:.2f})"
        )

    _move_development_only()
    saved = total_before - total_after
    print(
        f"runtime art: {_format_bytes(total_before)} -> "
        f"{_format_bytes(total_after)}; saved {_format_bytes(saved)}"
    )


if __name__ == "__main__":
    main()
