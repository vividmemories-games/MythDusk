#!/bin/sh
# Run from the repository root while tool/store_preview.dart is running.
set -eu
store_shots_dir=art_sources/store/google_play/v1/screenshots
mkdir -p "$store_shots_dir/sources"
for shot in 01_puzzle_combat 02_hero_skills 03_boss_encounter 04_heroes 05_campaign; do
  curl --fail --silent --show-error --max-time 45 \
    "http://127.0.0.1:18765/$shot" -o "$store_shots_dir/sources/$shot.png"
  sips -s format jpeg -s formatOptions 95 "$store_shots_dir/sources/$shot.png" \
    --out "$store_shots_dir/$shot.jpg"
done
