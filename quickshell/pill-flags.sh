#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# pill-flags.sh
# -----------------------------------------------------------------------------
#
# Makes the pill willing to use generated colours at all.
#
# Theme.qml ignores the colour file entirely while paletteMode is "static",
# which is its default -- it renders Ricelin's curated vermilion identity
# instead. So writing colours is only half of it, and this is the other half.
#
# Setup rather than theming, which is why it is not part of render-theme.lua:
# it is written once and does not change when the palette does.
#
# Merged rather than overwritten, because this file also holds the weather city,
# the wallpaper directory, recording settings and everything else the pill lets
# you change from its own UI. Writing it wholesale would reset all of that.

set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin"

mkdir -p "$STATE"

flags="$STATE/flags.json"

[[ -f "$flags" ]] || echo '{}' > "$flags"

jq '.paletteMode = "dynamic"' "$flags" > "$flags.tmp" && mv "$flags.tmp" "$flags"

echo "set paletteMode=dynamic in $flags"
