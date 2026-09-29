#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# apply-palette.sh
# -----------------------------------------------------------------------------
#
# Makes the vendored pill wear this repo's scheme instead of its own.
#
# The pill reads colours from one JSON file and hot-reloads it -- Dyn.qml
# watches it with FileView. So theming it is writing that file, and a theme
# switch is writing it again; nothing restarts.
#
# Two files, because one without the other does nothing:
#
#   $XDG_CACHE_HOME/ricelin/colors.json   the colours themselves
#   $XDG_STATE_HOME/ricelin/flags.json    paletteMode, which must not be
#                                         "static" or Theme.qml ignores the
#                                         colours and renders their curated
#                                         vermilion identity instead
#
# The values come from lib/palette.lua, so the compositor and the bar are drawn
# from one source rather than two that drift. At P6 matugen writes colors.json
# from the wallpaper and this script becomes the fallback path.

set -euo pipefail

DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ricelin"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin"

mkdir -p "$CACHE" "$STATE"

# -----------------------------------------------------------------------------
# Colours
# -----------------------------------------------------------------------------

# Read through Lua rather than parsed out of the file, so the mapping below sees
# exactly what the compositor sees -- including anything palette.lua computes.
#
# The token names on the left are Material You's, which is what the pill was
# written against and what matugen emits. Mapping our ramp onto them is the
# whole translation: surfaces ascend base -> raised -> overlay -> muted, the
# accent pair carries focus, and the text family stays neutral so it keeps its
# contrast on any of those surfaces.
lua - "$DESKTOP_DIR" > "$CACHE/colors.json" <<'LUA'
package.path = arg[1] .. "/?.lua;" .. package.path
local p = require("lib.palette")

local map = {
    surface                   = p.base,
    surface_container         = p.raised,
    surface_container_low     = p.root,
    surface_container_high    = p.overlay,
    surface_container_highest = p.muted,

    primary                   = p.accent,
    primary_container         = p.accent_deep,
    on_primary_container      = p.fg_bright,

    outline                   = p.muted,
    outline_variant           = p.raised,

    cream                     = p.fg,
    bright                    = p.fg_bright,
    subtle                    = p.fg_muted,
    dim                       = p.fg_dim,
    faint                     = p.muted,
    icon_dim                  = p.fg_muted,
    tick_rest                 = p.fg_muted,
}

-- Written in a fixed order so the file is stable across runs and a diff shows
-- a colour change rather than a reshuffle.
local order = {
    "surface", "surface_container", "surface_container_low",
    "surface_container_high", "surface_container_highest",
    "primary", "primary_container", "on_primary_container",
    "outline", "outline_variant",
    "cream", "bright", "subtle", "dim", "faint", "icon_dim", "tick_rest",
}

local out = {}
for i, key in ipairs(order) do
    out[#out + 1] = string.format('  "%s": "%s"%s', key, map[key], i < #order and "," or "")
end

print("{\n" .. table.concat(out, "\n") .. "\n}")
LUA

echo "wrote $CACHE/colors.json"

# -----------------------------------------------------------------------------
# Flags
# -----------------------------------------------------------------------------

# Merged rather than overwritten: this file also holds the weather city, the
# wallpaper directory, recording settings and everything else the pill lets you
# change from its own UI. Writing it wholesale would reset all of that every
# time the theme is applied.
flags="$STATE/flags.json"

[[ -f "$flags" ]] || echo '{}' > "$flags"

jq '.paletteMode = "dynamic"' "$flags" > "$flags.tmp" && mv "$flags.tmp" "$flags"

echo "set paletteMode=dynamic in $flags"
