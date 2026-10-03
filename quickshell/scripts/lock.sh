#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# lock.sh
# -----------------------------------------------------------------------------
#
# Locks the session, whatever is currently doing the locking.
#
# One entry point with two callers that would otherwise each need to know the
# answer: the bar's power menu, which hardcodes this path in vendored code, and
# hypridle, which is a static conf file with no way to ask.
#
# It resolves the `lock` role rather than naming a program, so switching a rice
# to a different lock screen changes this too. That is also what removed the
# last hardcoded ~/.dotfiles path from the desktop: hypridle.conf used to spell
# out the hyprlock command and its config, and now calls this instead.
#
# Upstream's version of this script does something else entirely -- it grabs a
# screenshot per monitor and pokes a file watch, because their lock surface
# reveals onto those grabs. Ours runs a separate program, so there is nothing to
# capture first.

set -euo pipefail

# `pwd -P`, not `pwd`: bash's cd is logical, so this used to come back as the
# symlink it was invoked through and the strip below never fired.
#
# That broke locking outright rather than degrading it. Both callers use the
# ~/.config/hypr/scripts path -- hypridle.conf and the pill's power menu -- so
# DESKTOP pointed at the symlink, lib.roles was not on package.path, the
# command came back empty and this exited 1. No idle lock, no lock from the
# menu, and no lock before sleep.
SCRIPTS_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# The symlink this is reached through lands in ~/.config/hypr/scripts, so the
# desktop directory is worked out from the real file rather than from $0.
DESKTOP="${SCRIPTS_DIR%/quickshell/scripts}"

# Without this a second lock screen stacks on the first and the session needs
# both dismissed. Kept here rather than in hypridle.conf so it protects every
# caller, not just the idle timer.
pidof hyprlock > /dev/null 2>&1 && exit 0

command="$(
    lua -e "package.path='$DESKTOP/?.lua;'..package.path
            hl = { dsp = { exec_cmd = function(c) return c end, exit = function() end } }
            print(require('lib.roles').action_command('lock'))" 2> /dev/null
)"

[[ -n "$command" ]] || {
    echo "no lock provider resolved" >&2
    exit 1
}

exec sh -c "$command"
