#!/bin/sh

# -----------------------------------------------------------------------------
# display-apply.sh
# -----------------------------------------------------------------------------
#
# Applies a monitor mode for the pill's Display surface, with a way back.
#
#   display-apply.sh apply <output> <WxH@Hz> <XxY> <scale>
#   display-apply.sh keep <output>
#   display-apply.sh revert <output>
#
# `apply` snapshots the output's current mode, position and scale, applies the
# new spec live, and arms a detached watchdog that puts the snapshot back after
# 12 seconds unless `keep` lands first. The surface shows the countdown and
# calls `keep` on confirm or `revert` on close -- but the watchdog is the real
# safety: a mode the monitor cannot display blanks the screen, and a blanked
# screen cannot click Confirm. Detached (setsid, no tty), it survives the pill
# crashing too.
#
# Upstream Ricelin ships a script of this name; this one is written fresh
# because theirs drives `hyprctl keyword`, which this desktop's Lua config
# refuses ("keyword can't work with non-legacy parsers") -- so everything here
# goes through `hyprctl eval` running the same `hl.monitor` the config uses.
# Persistence is not this script's job: the surface rewrites local.lua itself
# once the change is confirmed. This script only touches the live compositor.
#
# POSIX sh on purpose: the surface invokes it as `sh "$helper" ...`, so the
# shebang never runs and bashisms would break under a strict /bin/sh.
#
# The snapshot lives in $XDG_RUNTIME_DIR: it exists to survive a pill crash,
# not a logout -- a revert armed in one session must never fire into the next,
# and the runtime dir is cleared exactly on that boundary.

set -eu

usage() {
    echo "usage: display-apply.sh apply <output> <WxH@Hz> <XxY> <scale> | keep <output> | revert <output>" >&2
    exit 1
}

[ $# -ge 2 ] || usage
verb=$1
out=$2

# Everything below reaches `hyprctl eval` inside a Lua string, so nothing
# unvalidated may pass. The shapes are exactly what the surface sends: an
# output name, a mode, a position (negative coordinates are real -- a monitor
# left of the origin), and one of the four scale presets.
case "$out" in
    *[!A-Za-z0-9-]* | "") echo "display-apply: bad output name: $out" >&2; exit 1 ;;
esac

rundir="${XDG_RUNTIME_DIR:-/tmp/display-apply-$(id -u)}/dotfiles-display"
snap="$rundir/$out"

# Applies one spec to the live compositor. hyprctl exits non-zero when the
# eval does not parse or the dispatcher refuses, which is what callers check.
eval_monitor() {
    hyprctl eval "hl.monitor({
        output = \"$1\",
        mode = \"$2\",
        position = \"$3\",
        scale = $4,
    })" > /dev/null
}

# Puts the snapshot back and removes it. A missing snapshot is success: the
# change was already kept or reverted, and doing nothing is the right amount.
revert_now() {
    [ -f "$snap" ] || return 0
    mode=$(sed -n 1p "$snap")
    pos=$(sed -n 2p "$snap")
    scale=$(sed -n 3p "$snap")
    rm -f "$snap"
    eval_monitor "$out" "$mode" "$pos" "$scale"
}

# Stops a pending watchdog. The snapshot is removed before the kill so a
# watchdog already past its sleep finds nothing to revert -- the file is the
# arm switch, the process is just the timer.
disarm() {
    rm -f "$snap"
    if [ -f "$snap.pid" ]; then
        kill "$(cat "$snap.pid")" 2> /dev/null || true
        rm -f "$snap.pid"
    fi
}

case "$verb" in
    apply)
        [ $# -eq 5 ] || usage
        mode=$3 pos=$4 scale=$5
        case "$mode" in
            *[!0-9x@.]* | "") echo "display-apply: bad mode: $mode" >&2; exit 1 ;;
        esac
        case "$pos" in
            *[!0-9x-]* | "") echo "display-apply: bad position: $pos" >&2; exit 1 ;;
        esac
        case "$scale" in
            *[!0-9.]* | "") echo "display-apply: bad scale: $scale" >&2; exit 1 ;;
        esac

        mkdir -p "$rundir"

        # Snapshot before touching anything. An output hyprctl does not list
        # cannot be snapshotted, so it cannot be safely changed: fail here,
        # which is the error the surface reports.
        current=$(hyprctl monitors -j | jq -r --arg out "$out" \
            '.[] | select(.name == $out) | "\(.width)x\(.height)@\(.refreshRate)\n\(.x)x\(.y)\n\(.scale)"')
        [ -n "$current" ] || { echo "display-apply: no such output: $out" >&2; exit 1; }

        # A second apply while one is pending keeps the FIRST snapshot -- that
        # is the state the user started from, and reverting must land there,
        # not on an intermediate mode. Only the watchdog is re-armed.
        if [ ! -f "$snap" ]; then
            printf '%s\n' "$current" > "$snap"
        elif [ -f "$snap.pid" ]; then
            kill "$(cat "$snap.pid")" 2> /dev/null || true
        fi

        if ! eval_monitor "$out" "$mode" "$pos" "$scale"; then
            rm -f "$snap" "$snap.pid"
            exit 1
        fi

        # Detached so it outlives the pill and holds no tty. Its own pid lands
        # in the pidfile from inside, after setsid has reparented it.
        setsid -f sh "$0" watchdog "$out" < /dev/null > /dev/null 2>&1
        ;;

    watchdog)
        echo $$ > "$snap.pid"
        sleep 12
        rm -f "$snap.pid"
        revert_now
        ;;

    keep)
        disarm
        ;;

    revert)
        if [ -f "$snap.pid" ]; then
            kill "$(cat "$snap.pid")" 2> /dev/null || true
            rm -f "$snap.pid"
        fi
        revert_now
        ;;

    *) usage ;;
esac
