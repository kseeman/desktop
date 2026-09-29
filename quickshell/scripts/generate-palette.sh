#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# generate-palette.sh
# -----------------------------------------------------------------------------
#
# Derives this desktop's palette from an image, via matugen.
#
#   generate-palette.sh <image>
#
# Writes a Lua table with the same twelve names lib/palette.lua uses, so a rice
# asking for a generated palette gets one shaped exactly like a hand-written
# one. Nothing downstream can tell the difference, which is the point -- every
# consumer already reads those names and no config carries a colour.
#
# Dark scheme only. matugen produces both, and this desktop assumes dark
# throughout: the foregrounds are light and the surfaces near-black. Supporting
# light would mean every consumer template growing a second branch.
#
# Run unconditionally after a wallpaper change rather than only for rices that
# want it. Generating is cheap, and doing it always means switching a rice to
# dynamic works immediately instead of waiting for the next wallpaper.

set -euo pipefail

IMAGE="${1:?generate-palette.sh needs an image}"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/theme"
OUT="$CACHE/palette-generated.lua"

command -v matugen > /dev/null || {
    echo "matugen is not installed; no palette generated" >&2
    exit 0
}

# --prefer is not optional. With several candidate source colours and no
# terminal attached -- which is always, since this runs from a script -- matugen
# refuses rather than choosing, and the error is about a missing preference
# rather than anything to do with the image.
#
# saturation picks the most colourful candidate, which is the one a wallpaper is
# usually recognisable by. darkness or lightness would tend to pick whatever
# corner of the image happens to be emptiest.
json="$(matugen image "$IMAGE" --json hex --prefer saturation 2> /dev/null)" || {
    echo "matugen could not read $IMAGE" >&2
    exit 0
}

get() {
    printf '%s' "$json" | jq -r ".colors.\"$1\".dark.color // empty"
}

# Midpoint of two colours, per channel.
#
# Needed because our text ramp has four steps and matugen's usable text tokens
# give three: on_surface, on_surface_variant and outline. The next one down,
# outline_variant, is a divider colour and far too dark to read as text. Rather
# than point two of our names at one value and lose a level, the missing step is
# the blend of the two either side of it.
blend() {
    local a="${1#\#}" b="${2#\#}" out="#"
    local i ca cb

    for i in 0 2 4; do
        ca=$((16#${a:$i:2}))
        cb=$((16#${b:$i:2}))
        out+=$(printf '%02X' $(((ca + cb) / 2)))
    done

    printf '%s' "$out"
}

# -----------------------------------------------------------------------------
# The mapping
# -----------------------------------------------------------------------------
#
# Material You's ramp on the left, ours on the right. This is the same
# correspondence quickshell/pill-colors.json.in makes in the other direction --
# lib/palette.lua was written in Material You's shape precisely so this stayed
# mechanical rather than a matter of taste.

root="$(get surface_container_lowest)"
base="$(get surface_container_low)"
raised="$(get surface_container)"
overlay="$(get surface_container_high)"
muted="$(get surface_container_highest)"

# Between root and base: a panel ground that reads as darker than the windows
# it sits above.
bar="$(get surface)"

accent="$(get primary)"
accent_deep="$(get primary_container)"

fg_bright="$(get on_surface)"
fg="$(get on_surface_variant)"
fg_dim="$(get outline)"
fg_muted="$(blend "$fg" "$fg_dim")"

# A missing token means matugen changed shape, and half a palette is worse than
# none: the floor in lib/palette.lua is grey on purpose, so falling back to it
# looks plainly wrong rather than plausibly right.
for name in root base raised overlay muted bar accent accent_deep fg fg_bright fg_muted fg_dim; do
    [[ -n "${!name}" ]] || {
        echo "matugen did not provide $name; leaving the palette alone" >&2
        exit 1
    }
done

mkdir -p "$CACHE"

cat > "$OUT" <<LUA
-- Generated from $(basename "$IMAGE") by generate-palette.sh. Do not edit:
-- the next wallpaper change overwrites this file.
return {
    root = "$root",
    base = "$base",
    raised = "$raised",
    overlay = "$overlay",
    muted = "$muted",

    accent = "$accent",
    accent_deep = "$accent_deep",

    bar = "$bar",

    fg = "$fg",
    fg_bright = "$fg_bright",
    fg_muted = "$fg_muted",
    fg_dim = "$fg_dim",
}
LUA

echo "palette generated from $(basename "$IMAGE")"
