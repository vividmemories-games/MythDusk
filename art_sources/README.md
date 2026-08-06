# Art sources

Files in this directory are source or development-only artwork and are not
included in the Flutter asset bundle.

- `runtime_png/` contains the editable PNG originals for runtime WebP assets.
- `development/` contains backups and references that must not ship.

Regenerate optimized runtime assets with:

```bash
python3 scripts/optimize_runtime_assets.py --apply
```

The optimizer preserves dimensions and alpha, applies category-specific WebP
quality settings, and rejects conversions that exceed its visual error limit.
