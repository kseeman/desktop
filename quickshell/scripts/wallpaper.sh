#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# wallpaper.sh
# -----------------------------------------------------------------------------
#
# Sets the wallpaper, and tells the bar where the wallpapers are.
#
#   wallpaper.sh resolve            work out the folder, record it
#   wallpaper.sh set <path> [out]   set it, optionally on one output only
#   wallpaper.sh current            print what is set
#
# The bar calls the first two; the contract is theirs, not ours. Singletons/
# Walls.qml runs `resolve` before listing and `set` when you pick something, and
# reads back two state files -- one naming the current wallpaper, one the
# folder. Those paths are fixed by the vendored code, which is why they are
# spelled "ricelin" here.
#
# Ricelin's own version is ten kilobytes: shuffle bags, video wallpapers,
# per-output still-frame extraction, a matugen call and a terminal reload. This
# does the two things the picker needs. The rest can be added if it turns out to
# be wanted, rather than carried because it was there.
#
# -----------------------------------------------------------------------------
# Fitting
# -----------------------------------------------------------------------------
#
# **Never stretch.** awww's default is `crop`, which fills the screen and
# discards what does not fit while keeping the aspect ratio -- the distortion
# that made wallpapers look wrong under HyDE is not inherited here.
#
# On a 5120x1440 ultrawide, crop keeps the width and discards roughly 60% of a
# 16:9 image's height, and --crop-gravity chooses which part survives. When that
# loses too much, DOTFILES_WALLPAPER_RESIZE=fit shows the whole image and pads
# it -- with the palette's darkest colour rather than black, so the padding
# reads as part of the desktop.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE="$STATE_HOME/ricelin-wallpaper"
DIR_STATE="$STATE_HOME/ricelin-wallpaper-dir"

FLAGS="$STATE_HOME/ricelin/flags.json"

RESIZE="${DOTFILES_WALLPAPER_RESIZE:-crop}"
GRAVITY="${DOTFILES_WALLPAPER_GRAVITY:-center}"

# The padding colour when fitting. Read through the palette so it follows the
# active rice, the same as every other colour here.
#
# The symlink this script is reached through lands in ~/.config/hypr/scripts, so
# the desktop directory is two levels up from the real file rather than from $0.
fill_color() {
    local desktop="${SCRIPTS_DIR%/quickshell/scripts}"

    lua -e "package.path='$desktop/?.lua;'..package.path
            print((require('lib.palette').root:gsub('^#','')))" 2> /dev/null || echo "000000"
}

# -----------------------------------------------------------------------------
# Where the wallpapers are
# -----------------------------------------------------------------------------

# In the bar's own order of preference, so the folder it lists is the folder
# this sets from. An explicit choice in its settings wins; otherwise whatever
# was resolved last; otherwise the conventional place.
resolve_dir() {
    local dir=""

    if [[ -f "$FLAGS" ]]; then
        dir="$(jq -r '.wallpaperDir // ""' "$FLAGS" 2> /dev/null || true)"
    fi

    [[ -n "$dir" ]] || dir="$(cat "$DIR_STATE" 2> /dev/null || true)"
    [[ -n "$dir" ]] || dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/wallpapers"

    printf '%s' "$dir"
}

cmd_resolve() {
    local dir
    dir="$(resolve_dir)"

    mkdir -p "$dir" "$(dirname "$DIR_STATE")"
    printf '%s\n' "$dir" > "$DIR_STATE"
    printf '%s\n' "$dir"
}

# -----------------------------------------------------------------------------
# Setting
# -----------------------------------------------------------------------------

# awww is a client; without its daemon every call fails with a connection
# error. Started here rather than from autostart so the first wallpaper of a
# session works whether or not anything else has run.
ensure_daemon() {
    awww query > /dev/null 2>&1 && return 0

    command -v awww-daemon > /dev/null || {
        echo "awww-daemon is not installed" >&2
        return 1
    }

    awww-daemon > /dev/null 2>&1 &

    for _ in $(seq 1 40); do
        awww query > /dev/null 2>&1 && return 0
        sleep 0.1
    done

    echo "awww-daemon did not come up" >&2
    return 1
}

cmd_set() {
    local pic="${1:?set needs a path}"
    local output="${2:-}"

    [[ -f "$pic" ]] || {
        echo "no such wallpaper: $pic" >&2
        exit 1
    }

    ensure_daemon

    local -a args=(img)
    [[ -n "$output" ]] && args+=(--outputs "$output")

    args+=(--resize "$RESIZE" --fill-color "$(fill_color)")

    # Only meaningful while cropping, and awww rejects it otherwise.
    [[ "$RESIZE" == "crop" ]] && args+=(--crop-gravity "$GRAVITY")

    # A transition rather than a cut, matched to the desktop's own motion: the
    # bar and the compositor both settle over roughly 400ms.
    args+=(--transition-type fade --transition-duration 0.4 --transition-fps 60)

    awww "${args[@]}" "$pic"

    # Written last: the bar reads this back to mark which wallpaper is current,
    # so recording one that failed to apply would show the wrong thing.
    #
    # Only for a whole-desktop change. A per-output set leaves the others as
    # they were, so there is no single "current" to record.
    if [[ -z "$output" ]]; then
        mkdir -p "$(dirname "$STATE")"
        printf '%s\n' "$pic" > "$STATE"

        # Unconditionally, rather than only for rices that derive their
        # colours. Generating is cheap, and doing it always means switching a
        # rice to dynamic takes effect immediately instead of waiting for the
        # next wallpaper. Whether the palette is *used* is decided in
        # lib/palette.lua, which is the layer that should decide it.
        #
        # Best effort: a missing matugen or an image it cannot read leaves the
        # previous palette in place rather than failing the wallpaper change.
        "$SCRIPTS_DIR/generate-palette.sh" "$pic" || true

        repaint
    fi
}

# Push a regenerated palette out to the things that read it.
#
# Only for a rice that derives its colours: for any other, the palette did not
# change and re-rendering would be churn ending in a compositor reload nobody
# asked for.
#
# Without this a wallpaper change on a dynamic rice would rewrite
# palette-generated.lua and stop there -- the new colours would not appear until
# something else happened to re-render, which is a confusing way for a feature
# whose whole point is that the desktop follows the picture to behave.
repaint() {
    local desktop="${SCRIPTS_DIR%/quickshell/scripts}"
    local from

    from="$(lua -e "package.path='$desktop/?.lua;'..package.path
                    print(require('lib.rice').palette_from)" 2> /dev/null || true)"

    [[ "$from" == "wallpaper" ]] || return 0

    lua "$desktop/render-theme.lua" > /dev/null || return 0

    # The bar watches its own colour file and repaints itself; the compositor
    # has to be told.
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && hyprctl reload > /dev/null 2>&1

    return 0
}

cmd_current() {
    cat "$STATE" 2> /dev/null || true
}

case "${1:-current}" in
    resolve) cmd_resolve ;;
    set)
        shift
        cmd_set "$@"
        ;;
    current) cmd_current ;;
    --help | -h) sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//' ;;
    *)
        echo "wallpaper.sh: unknown command: $1" >&2
        exit 1
        ;;
esac
