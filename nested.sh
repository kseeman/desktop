#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# nested.sh
# -----------------------------------------------------------------------------
#
# Runs a second Hyprland inside a window of the current session, so a change can
# be tried without logging out of the one being used.
#
#   nested.sh                       the repo's config, in a window
#   nested.sh --lock                lock it immediately, to test the lock screen
#   nested.sh --exec waybar         start something inside it
#   nested.sh --config other.lua    a different config entirely
#
# SUPER+SHIFT+Q closes it. Closing the window works too.
#
# -----------------------------------------------------------------------------
# Why this exists
# -----------------------------------------------------------------------------
#
# Most of this desktop can be checked with verify-config.sh, and bindings apply
# to the running session with `hyprctl reload`. Two things cannot:
#
#   the lock screen   testing it for real means locking yourself out if it is
#                     wrong. --grace is not a preview: any input dismisses it,
#                     so the input field cannot be inspected or typed into.
#   autostart         hl.on("hyprland.start") fires once per session, and
#                     `hyprctl reload` does not re-fire it.
#
# Both of those used to need a logout. Here they need a window.
#
# The nested instance gets its own keybinds, its own autostart and its own lock,
# and none of it touches the session it runs inside.

set -euo pipefail

DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG="$DESKTOP_DIR/init.lua"
LOCK=false
EXEC=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lock)
            LOCK=true
            ;;
        --exec)
            EXEC="${2:?--exec needs a command}"
            shift
            ;;
        --config)
            CONFIG="${2:?--config needs a file}"
            shift
            ;;
        --help | -h)
            sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "nested.sh: unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

# A nested compositor needs one to nest inside.
[[ -n "${WAYLAND_DISPLAY:-}" ]] || {
    echo "No WAYLAND_DISPLAY: there is no session to nest inside." >&2
    exit 1
}

# The generated config lives in the scratch area rather than beside the real
# one, so a stray file can never be picked up by a login.
generated="$(mktemp --suffix=.lua)"
trap 'rm -f "$generated"' EXIT

{
    printf 'dofile("%s")\n\n' "$CONFIG"

    # Its own quit binding. The nested instance has its own keymap, so this
    # cannot collide with the session outside it.
    printf 'hl.bind("SUPER + SHIFT + Q", hl.dsp.exit(), { desc = "close this nested session" })\n'

    if [[ "$LOCK" == true || -n "$EXEC" ]]; then
        printf '\nhl.on("hyprland.start", function()\n'

        # Inside hl.on, not at the top level: verifying a config runs it, and a
        # top-level exec would launch these when the config is merely checked.
        [[ "$LOCK" == true ]] &&
            printf '    hl.exec_cmd("hyprlock -c %s/hyprlock.conf")\n' "$DESKTOP_DIR"

        [[ -n "$EXEC" ]] &&
            printf '    hl.exec_cmd("%s")\n' "$EXEC"

        printf 'end)\n'
    fi
} > "$generated"

# Checked before it runs, the same as the real config is -- a nested session
# that dies on a config error is a worse signal than one that refuses to start.
if ! "$DESKTOP_DIR/verify-config.sh" "$generated" > /dev/null; then
    echo "The generated nested config does not verify:" >&2
    "$DESKTOP_DIR/verify-config.sh" "$generated" >&2
    exit 1
fi

echo "Starting a nested Hyprland. SUPER+SHIFT+Q closes it."

Hyprland --config "$generated"
