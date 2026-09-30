#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# dolphin-layout.sh
# -----------------------------------------------------------------------------
#
# Sets Dolphin's dock geometry: a narrow right dock and a tall Places panel.
#
#   dolphin-layout.sh [--dry-run]
#
# Dolphin's default puts a huge preview icon and a short Places list in a wide
# right dock, which wastes most of it on one folder picture. This narrows the
# dock and gives the height to Places.
#
# **The preview scales with the dock's width, not its height.** Shortening the
# information panel alone leaves the icon exactly as big, which is the thing
# worth knowing before reaching for the splitter.
#
# -----------------------------------------------------------------------------
# Why this is a script and not a config file
# -----------------------------------------------------------------------------
#
# Dolphin keeps its dock layout as a base64 QMainWindow::saveState blob in
# dolphinstaterc, keyed by screen resolution, and rewrites it on exit. There is
# no ini key for any of this, so a tracked config file cannot express it and
# would be overwritten anyway.
#
# So the geometry is repo code and the state stays machine-local -- and because
# Dolphin rewrites the file when it quits, this refuses to run while it is
# open, or the change would be undone the moment the window closes.

set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dolphinstaterc"

# Width of the right dock. The preview icon is sized from this.
DOCK_WIDTH="${DOLPHIN_DOCK_WIDTH:-260}"

# Share of the right column given to Places; the information panel takes the
# rest. A share rather than a height, because the column's total depends on how
# tall the window was when Dolphin last saved -- a fixed number is right for one
# window size and wrong for every other.
PLACES_SHARE="${DOLPHIN_PLACES_SHARE:-0.7}"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

[[ -f "$STATE" ]] || {
    echo "No $STATE -- run Dolphin once first." >&2
    exit 1
}

if ! $DRY_RUN && pgrep -x dolphin > /dev/null; then
    echo "Dolphin is running, and rewrites this file when it exits." >&2
    echo "Close every window first, or the change goes back on quit." >&2
    exit 1
fi

DRY_RUN=$DRY_RUN DOCK_WIDTH=$DOCK_WIDTH PLACES_SHARE=$PLACES_SHARE \
    python3 - "$STATE" <<'PY'
import base64, os, re, struct, sys

path = sys.argv[1]
dry = os.environ["DRY_RUN"] == "true"
width = int(os.environ["DOCK_WIDTH"])
share = float(os.environ["PLACES_SHARE"])

text = open(path).read()
m = re.search(r"^State=(.*)$", text, re.M)

if not m:
    sys.exit("no State= line in " + path)

blob = bytearray(base64.b64decode(m.group(1)))

def name_at(name):
    i = blob.find(name.encode("utf-16-be"))
    if i < 0:
        sys.exit(f"{name} not found; Dolphin's layout is not the one this expects")
    return i

# Each dock item is: length-prefixed UTF-16 name, one flags byte, then
# pos, size, and two more ints. The dock *area* width sits 19 bytes ahead of
# the first item's name, which is what puts it before the area's own marker.
places_i = name_at("placesDock")
info_i = name_at("infoDock")

places_fields = places_i + len("placesDock") * 2 + 1
info_fields = info_i + len("infoDock") * 2 + 1
width_at = places_i - 19

old_width = struct.unpack_from(">i", blob, width_at)[0]
old_places = struct.unpack_from(">i", blob, places_fields + 4)[0]
old_info_pos = struct.unpack_from(">i", blob, info_fields)[0]
old_info = struct.unpack_from(">i", blob, info_fields + 4)[0]

# Refuse rather than write nonsense into a binary blob whose layout moved.
for label, value in (("dock width", old_width), ("places height", old_places),
                     ("info height", old_info)):
    if not 0 < value < 20000:
        sys.exit(f"{label} read as {value}; refusing to patch a blob this does not understand")

# The column total is preserved, so whatever height Dolphin last saved still
# adds up after the split moves.
total = old_places + old_info
places = int(total * share)
info = total - places

if not 0.1 <= share <= 0.9:
    sys.exit(f"share {share} is outside 0.1-0.9")

print(f"    dock width     {old_width} -> {width}")
print(f"    places height  {old_places} -> {places}")
print(f"    info height    {old_info} -> {info}")

if dry:
    print("    (dry run, nothing written)")
    sys.exit(0)

struct.pack_into(">i", blob, width_at, width)
struct.pack_into(">i", blob, places_fields + 4, places)
struct.pack_into(">i", blob, info_fields, old_info_pos - (old_places - places))
struct.pack_into(">i", blob, info_fields + 4, info)

encoded = base64.b64encode(bytes(blob)).decode()
open(path, "w").write(re.sub(r"^State=.*$", "State=" + encoded, text, flags=re.M))
PY

$DRY_RUN || echo "
==> Done. Open Dolphin to see it."
