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
# **Never stretch.** Aspect ratio is kept whatever the mode, so the distortion
# that made wallpapers look wrong under HyDE is not inherited here.
#
# The mode is `wallpaper_fit` in lib/look.lua, defaulting to `fit`: the whole
# image is shown and the rest padded. awww's own default is `crop`, which fills
# the screen and discards the overflow -- on the 32:9 ultrawide this was written
# for, a 16:9 image silently loses half its height, which looks like a stretch
# without being one. fit fails visibly instead.
#
# The cost is real and worth knowing: fit puts a 16:9 image in the middle 2560
# of 5120 pixels. Whichever way, a screen and an image of different shapes give
# up something. `crop` plus `wallpaper_gravity` is the better trade for a
# collection that mostly matches the screen.
#
# `wallpaper_fill` decides what the padding is -- by default the image's own
# darkest surface, so it belongs to the picture rather than to the rice.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE="$STATE_HOME/ricelin-wallpaper"
DIR_STATE="$STATE_HOME/ricelin-wallpaper-dir"

FLAGS="$STATE_HOME/ricelin/flags.json"

# The symlink this script is reached through lands in ~/.config/hypr/scripts, so
# the desktop directory is two levels up from the real file rather than from $0.
DESKTOP_DIR="${SCRIPTS_DIR%/quickshell/scripts}"

# Ask the active look for a knob. Empty on any failure, so every caller keeps
# its own default rather than this one inventing a second set.
look() {
    lua -e "package.path='$DESKTOP_DIR/?.lua;'..package.path
            io.write(tostring(require('lib.look')['$1'] or ''))" 2> /dev/null || true
}

# Env beats the look, which beats the built-in -- the usual order. The env vars
# stay because a one-off is worth having without editing a rice; they are not
# how this is configured.
RESIZE="${DOTFILES_WALLPAPER_RESIZE:-$(look wallpaper_fit)}"
RESIZE="${RESIZE:-fit}"

GRAVITY="${DOTFILES_WALLPAPER_GRAVITY:-$(look wallpaper_gravity)}"
GRAVITY="${GRAVITY:-center}"

FILL="${DOTFILES_WALLPAPER_FILL:-$(look wallpaper_fill)}"
FILL="${FILL:-sampled}"

# Resolve `wallpaper_fill` to six hex digits, which is what awww wants.
#
#   "sampled"   the current image's darkest surface, from the generated palette
#   "#RRGGBB"   a literal, passed through
#   "<name>"    a palette token, read through lib.palette so it follows the rice
#
# `sampled` reads palette-generated.lua directly rather than lib.palette,
# because that file is written on every wallpaper change while lib.palette only
# *uses* it for a rice that asked for a generated palette. The padding should
# follow the picture whether or not the rice does.
#
# Every path falls back rather than failing: padding is cosmetic, and no colour
# is worth refusing to set a wallpaper over.
fill_color() {
    local generated="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/theme/palette-generated.lua"
    local value=""

    case "$FILL" in
        sampled)
            value="$(lua -e "local ok,p = pcall(dofile, '$generated')
                             io.write(ok and p and p.root or '')" 2> /dev/null || true)"
            ;;
        \#*)
            value="$FILL"
            ;;
        *)
            value="$(lua -e "package.path='$DESKTOP_DIR/?.lua;'..package.path
                             io.write(tostring(require('lib.palette')['$FILL'] or ''))" 2> /dev/null || true)"
            ;;
    esac

    # A sampled palette that is not there yet -- first wallpaper of a fresh
    # machine, or no matugen -- falls to the rice's own darkest surface, and
    # black underneath that.
    [[ -n "$value" ]] || value="$(lua -e "package.path='$DESKTOP_DIR/?.lua;'..package.path
                                          io.write(tostring(require('lib.palette').root or ''))" 2> /dev/null || true)"

    printf '%s' "${value:-#000000}" | sed 's/^#//'
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

    # A recorded directory is only worth having if it still exists. Without this
    # check a rename can never heal: resolve keeps returning the old path, and
    # since it creates what it names, reading it puts the empty directory back.
    local recorded
    recorded="$(cat "$DIR_STATE" 2> /dev/null || true)"
    [[ -n "$recorded" && -d "$recorded" ]] && dir="$recorded"

    # Capitalised to match the other XDG user directories -- xdg-user-dirs
    # creates Pictures, Downloads and Documents that way, and Screenshots beside
    # this one follows suit.
    [[ -n "$dir" ]] || dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"

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
# Working around awww's fit
# -----------------------------------------------------------------------------
#
# awww 0.12.1 ignores --resize fit when the image width exactly equals the
# output width, and crops instead. Measured against this 5120x1440 panel:
# 5120x2880 and 5120x2160 crop, while 5000x2880, 5000x2812 and 6000x3375 fit.
# So it is width equality -- scale factors of 1.024 and 0.853 both work and
# 1.000 does not -- and neither the transition nor the fill colour is involved.
#
# It bites exactly the wallpapers cut to a screen's own width, which is the
# collection an ultrawide accumulates, so it is worth working around rather
# than waiting on.
#
# The workaround is to do awww's job for it: render the image into a frame the
# size of the output, padded, and hand that over with --resize no. There is no
# flag that avoids this -- the bug is in the resize path itself.
#
# Only for the affected outputs, and only in fit mode. Everything else takes
# the unchanged single awww call below, so the common wallpaper pays nothing.

RENDER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/wallpaper"

# Name, width and height of every output awww knows about.
#
#   : DP-1: 5120x1440, scale: 1, currently displaying: image: /path
#
# Asking awww rather than hyprctl keeps this working with no compositor
# connection, which is also how ensure_daemon leaves things on first run.
#
# The scale field is read past. Every output here is scale 1, so whether awww
# reports logical or physical pixels for a scaled one is untested -- on a HiDPI
# output the frame could come out at half size. Worth checking before trusting
# this on a laptop.
awww_outputs() {
    awww query | sed -n 's/^: \([^:]*\): \([0-9]\+\)x\([0-9]\+\),.*/\1 \2 \3/p'
}

# Does this image hit the bug on an output of this width?
#
# `[0]` takes the first frame: identify prints one line per frame otherwise, and
# an animated gif would yield a width with a newline in it.
hits_fit_bug() {
    local pic="$1" output_width="$2" image_width

    [[ "$RESIZE" == "fit" ]] || return 1
    command -v magick > /dev/null || return 1

    image_width="$(magick identify -format '%w' "${pic}[0]" 2> /dev/null)" || return 1

    [[ "$image_width" == "$output_width" ]]
}

# Render `pic` into a `w`x`h` frame: scaled to fit, centred, padded with `fill`.
#
# -resize without `!` keeps the aspect ratio and fits inside the box, then
# -extent pads it out to exactly the box -- which is what fit means, done here
# because awww will not do it.
#
# The alpha is removed onto the same colour, so a transparent PNG pads and fills
# identically instead of showing whatever awww puts behind it.
#
# One file per output rather than a keyed cache: re-rendering costs a few
# hundred milliseconds and only happens for affected wallpapers, while a keyed
# cache of 5120x1440 frames would need pruning to stay honest.
prerender() {
    local pic="$1" w="$2" h="$3" fill="$4" out="$5"

    mkdir -p "$RENDER_DIR"

    magick "${pic}[0]" \
        -resize "${w}x${h}" \
        -background "#${fill}" -alpha remove -alpha off \
        -gravity center -extent "${w}x${h}" \
        "$out"
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

# One awww invocation. `mode` is separate from $RESIZE because a pre-rendered
# frame is already the size of its output and must not be resized again.
awww_apply() {
    local pic="$1" mode="$2" fill="$3" output="${4:-}"
    local -a args=(img)

    [[ -n "$output" ]] && args+=(--outputs "$output")

    args+=(--resize "$mode" --fill-color "$fill")

    # Only meaningful while cropping, and awww rejects it otherwise.
    [[ "$mode" == "crop" ]] && args+=(--crop-gravity "$GRAVITY")

    # A transition rather than a cut, matched to the desktop's own motion: the
    # bar and the compositor both settle over roughly 400ms.
    args+=(--transition-type fade --transition-duration 0.4 --transition-fps 60)

    awww "${args[@]}" "$pic"
}

cmd_set() {
    local pic="${1:?set needs a path}"
    local output="${2:-}"

    [[ -f "$pic" ]] || {
        echo "no such wallpaper: $pic" >&2
        exit 1
    }

    ensure_daemon

    # Before awww, not after, because `wallpaper_fill = "sampled"` reads the
    # palette this writes -- generating afterwards would pad every wallpaper
    # with the previous one's colour.
    #
    # Whole-desktop only, as before: a per-output set leaves the other screens
    # alone, so it has no business redefining the desktop's palette. Its padding
    # therefore comes from whichever image was set across everything last.
    #
    # Best effort: a missing matugen or an image it cannot read leaves the
    # previous palette in place rather than failing the wallpaper change.
    #
    # The window this opens: if awww then fails, the palette describes a
    # wallpaper that is not up. Nothing re-renders (repaint is below awww), so
    # the running desktop is unaffected until something else re-renders it.
    if [[ -z "$output" ]]; then
        "$SCRIPTS_DIR/generate-palette.sh" "$pic" || true
    fi

    local fill
    fill="$(fill_color)"

    # Which outputs need awww's fit doing for them. Each entry is
    # "<output> <rendered path>"; `plain` collects the rest.
    local -a rendered=() plain=()
    local name ow oh frame entry

    while read -r name ow oh; do
        [[ -n "$name" ]] || continue
        [[ -z "$output" || "$name" == "$output" ]] || continue

        if hits_fit_bug "$pic" "$ow"; then
            frame="$RENDER_DIR/$name.png"

            # A render that fails is not worth failing the wallpaper over: fall
            # through to awww, which crops. Wrong, but a wallpaper.
            if prerender "$pic" "$ow" "$oh" "$fill" "$frame" 2> /dev/null; then
                rendered+=("$name $frame")
            else
                echo "could not pre-render for $name; awww will crop it" >&2
                plain+=("$name")
            fi
        else
            plain+=("$name")
        fi
    done < <(awww_outputs)

    # Nothing affected: the original single call, setting every output at once.
    # Naming outputs individually would work too, but this keeps the untouched
    # path byte-for-byte what it was.
    if [[ ${#rendered[@]} -eq 0 ]]; then
        awww_apply "$pic" "$RESIZE" "$fill" "$output"
    else
        # Each affected output gets its own frame, so two screens of different
        # shapes each get their own padding rather than sharing one.
        [[ ${#plain[@]} -eq 0 ]] || for name in "${plain[@]}"; do
            awww_apply "$pic" "$RESIZE" "$fill" "$name"
        done

        for entry in "${rendered[@]}"; do
            awww_apply "${entry#* }" no "$fill" "${entry%% *}"
        done
    fi

    # Written last: the bar reads this back to mark which wallpaper is current,
    # so recording one that failed to apply would show the wrong thing.
    #
    # Only for a whole-desktop change. A per-output set leaves the others as
    # they were, so there is no single "current" to record.
    if [[ -z "$output" ]]; then
        mkdir -p "$(dirname "$STATE")"
        printf '%s\n' "$pic" > "$STATE"

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
    local from

    from="$(lua -e "package.path='$DESKTOP_DIR/?.lua;'..package.path
                    print(require('lib.rice').palette_from)" 2> /dev/null || true)"

    [[ "$from" == "wallpaper" ]] || return 0

    lua "$DESKTOP_DIR/render-theme.lua" > /dev/null || return 0

    # The bar watches its own colour file and repaints itself; the compositor
    # has to be told.
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && hyprctl reload > /dev/null 2>&1

    return 0
}

cmd_current() {
    local recorded
    recorded="$(cat "$STATE" 2> /dev/null || true)"

    # Same rule as the directory: a recorded path that no longer exists is not
    # an answer. The bar reads this to mark which wallpaper is current, and
    # naming a file that was moved or deleted would mark the wrong thing --
    # or nothing, while looking like it knew.
    [[ -n "$recorded" && -f "$recorded" ]] && printf '%s\n' "$recorded"

    return 0
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
