"""Seed v5 Screen Toolkit state without overwriting existing v5 data."""

import json
import os
import pathlib
import sys
import tempfile

if len(sys.argv) != 3:
    sys.exit("Usage: migrate-noctalia-state.py OLD_SETTINGS_JSON V5_PLUGIN_DATA_DIR")
source, target = map(pathlib.Path, sys.argv[1:])
if not source.exists():
    sys.exit(0)
old = json.loads(source.read_text())
if not isinstance(old, dict):
    sys.exit("Legacy Screen Toolkit settings must be a JSON object")
for field in ("colorHistory", "paletteColors"):
    if field in old and not isinstance(old[field], list):
        sys.exit(f"Legacy {field} must be a list; refusing a lossy import")
seeds = {
    "color-history.json": old.get("colorHistory", []),
    "results.json": {
        "paletteColors": old.get("paletteColors", []),
        "colorResult": {
            "hex": old.get("resultHex", ""),
            "rgb": old.get("resultRgb", ""),
            "hsl": old.get("resultHsl", ""),
            "hsv": old.get("resultHsv", ""),
            "capturePath": "",
            "cacheBust": 0,
        },
    },
}
target.mkdir(parents=True, exist_ok=True, mode=0o700)
for name, value in seeds.items():
    if (target / name).exists():
        continue
    # Atomic publication with exclusive creation: a retry never replaces user data.
    with tempfile.NamedTemporaryFile(mode="w", dir=target, delete=False) as temp:
        json.dump(value, temp)
        temp.write("\n")
        temp.flush()
        os.fsync(temp.fileno())
    path = pathlib.Path(temp.name)
    try:
        os.link(path, target / name)
    except FileExistsError:
        pass
    finally:
        path.unlink()
