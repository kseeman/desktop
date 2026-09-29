#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# rice.sh
# -----------------------------------------------------------------------------
#
# Which look the desktop is wearing.
#
#   rice.sh                 list them, marking the active one
#   rice.sh current         print the active name
#   rice.sh switch <name>   wear a different one
#
# A switch writes a state file, regenerates every config that carries a colour
# and reloads the compositor. Colours, gaps, rounding, blur and motion all
# change in place -- nothing restarts.
#
# **Swapping a provider is the exception and the command says so.** Changing
# which program fills a role means starting one and stopping another, and
# `hyprctl reload` re-reads the config without re-running autostart. Rather than
# manage processes, this reports that a re-login is needed and leaves it.
#
# **A switch is machine-wide, including from a worktree.** The state file and
# the rendered output live under $XDG_STATE_HOME and $XDG_CACHE_HOME -- one set
# per machine, not per checkout -- and the bar watches its colour file. So
# running this from a branch repaints the desktop you are sitting in, and there
# is no isolated way to try it: the bar's colour path is fixed by vendored code
# and cannot be redirected. Switch back when you are done.

set -euo pipefail

DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RICES_DIR="$DESKTOP_DIR/rices"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
STATE="$STATE_DIR/rice"

# Reads through the same module the compositor uses, so this can never disagree
# with what the session actually resolved.
lua_eval() {
    lua -e "package.path='$DESKTOP_DIR/?.lua;'..package.path
            hl = { dsp = { exec_cmd = function(c) return c end, exit = function() end } }
            $1"
}

current() {
    lua_eval 'print(require("lib.rice").name)'
}

wallpaper_of() {
    lua_eval 'print(require("lib.rice").wallpaper or "")'
}

start_commands() {
    lua_eval 'for _, c in ipairs(require("lib.roles").start_commands()) do print(c) end'
}

exists() {
    [[ -f "$RICES_DIR/$1/rice.lua" || -f "$RICES_DIR/$1/palette.lua" ]]
}

list() {
    local active
    active="$(current)"

    for dir in "$RICES_DIR"/*/; do
        [[ -d "$dir" ]] || continue

        local name description mark
        name="$(basename "$dir")"
        description="$(lua_eval "local d = dofile('$dir/rice.lua') print(d.description or '')" 2>/dev/null || true)"

        # A glyph rather than colour, so the list follows the terminal palette
        # like everything else here.
        mark="○"
        [[ "$name" == "$active" ]] && mark="●"

        printf '%s %-16s %s\n' "$mark" "$name" "$description"
    done
}

switch() {
    local name="${1:?switch needs a rice name}"

    if ! exists "$name"; then
        echo "No rice '$name' in $RICES_DIR" >&2
        echo "" >&2
        list >&2
        exit 1
    fi

    # Captured before the state changes, so the comparison below is against
    # what is actually running rather than what the new rice asks for.
    local before after
    before="$(start_commands)"

    mkdir -p "$STATE_DIR"
    echo "$name" > "$STATE"

    after="$(start_commands)"

    echo "==> $name"

    lua "$DESKTOP_DIR/render-theme.lua" --verbose

    # Only when the rice names one. A rice that does not is not asking for the
    # wallpaper to be cleared -- it simply has no opinion, and whatever is up
    # stays up.
    local wallpaper
    wallpaper="$(wallpaper_of)"

    if [[ -n "$wallpaper" ]]; then
        if [[ -f "$wallpaper" ]]; then
            "$DESKTOP_DIR/quickshell/scripts/wallpaper.sh" set "$wallpaper" \
                && echo "wallpaper -> $wallpaper"
        else
            echo "rice names a wallpaper that is not there: $wallpaper" >&2
        fi
    fi

    # Only when there is a session to reload. Running this from a TTY or over
    # SSH should still switch the state and regenerate the files.
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl > /dev/null; then
        hyprctl reload > /dev/null && echo "reloaded the compositor"
    else
        echo "no session to reload; applies at the next login"
    fi

    if [[ "$before" != "$after" ]]; then
        echo ""
        echo "This rice uses different programs, which a reload cannot swap."
        echo "Log out and back in to pick them up."
    fi
}

case "${1:-list}" in
    list) list ;;
    current) current ;;
    switch) switch "${2:-}" ;;
    --help | -h) sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//' ;;
    *)
        echo "rice.sh: unknown command: $1" >&2
        exit 1
        ;;
esac
