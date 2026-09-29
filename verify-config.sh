#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# verify-config.sh
# -----------------------------------------------------------------------------
#
# Checks a Hyprland config before it can reach a login. Hyprland parses the file
# without starting a session, so a broken config is caught here rather than at
# the point where the only way to read the error is from another machine.
#
#   verify-config.sh                 verify the repo's desktop config
#   verify-config.sh path/to/x.lua   verify one file
#
# Exits non-zero when the config has errors, so it works as an install step and
# as a pre-commit check. Exits 0 and says so when there is nothing to verify, or
# when Hyprland is not installed -- this repo also runs on macOS.
#
# -----------------------------------------------------------------------------
# The side-effect hazard
# -----------------------------------------------------------------------------
#
# --verify-config does not start a compositor, but a Lua config IS a Lua program
# and verifying it runs that program. Measured against Hyprland 0.56.2:
#
#   os.execute(...)      at the top level   runs
#   hl.exec_cmd(...)     at the top level   runs -- it launches the application
#   inside hl.on("hyprland.start", ...)     does not run
#
# So every exec in this desktop belongs inside hl.on("hyprland.start", ...),
# which is also how Hyprland's own example config is written. Get it wrong and
# verifying a config launches the autostart set -- on every commit, for a hook.
# The check below is a heuristic reminder, not a parser.

set -euo pipefail

DESKTOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG="${1:-$DESKTOP_DIR/init.lua}"

# -----------------------------------------------------------------------------
# Preconditions
# -----------------------------------------------------------------------------

if ! command -v Hyprland &> /dev/null; then
    echo "Hyprland not installed, skipping config verification."
    exit 0
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "No config to verify at $CONFIG"
    exit 0
fi

# -----------------------------------------------------------------------------
# Static check
# -----------------------------------------------------------------------------

# An exec at the start of a line is at the top level in any formatting this repo
# uses, since anything nested is indented. Deliberately a warning: it is a
# heuristic, and a false positive must not block a commit.
if grep -nE '^\s{0,3}hl\.exec_cmd|^\s{0,3}os\.execute' "$CONFIG" > /dev/null 2>&1; then
    echo "Warning: $CONFIG looks like it execs at the top level:"
    grep -nE '^\s{0,3}hl\.exec_cmd|^\s{0,3}os\.execute' "$CONFIG" | sed 's/^/    /'
    echo "    These run whenever the config is verified. Move them into"
    echo "    hl.on(\"hyprland.start\", function() ... end)."
    echo ""
fi

# -----------------------------------------------------------------------------
# Verify
# -----------------------------------------------------------------------------

echo "==> Verifying $CONFIG"

# Both conditions are checked on purpose. The exit status is correct on 0.56.2
# (1 for a bad config, 0 for a good one), but the parse result is also printed
# as a plain "config ok" line, and agreeing with both costs nothing against a
# future release where one of them changes.
output="$(Hyprland --verify-config -c "$CONFIG" 2>&1)" && status=0 || status=$?

if [[ $status -ne 0 ]] || ! grep -qx "config ok" <<< "$output"; then
    # The banner and the debug preamble are noise; everything after it is the
    # parse result, which is what someone fixing the config needs to read.
    echo "$output" | sed -n '/Config parsing result/,$p' | grep -v "Config parsing result" |
        sed '/^$/d' | sed 's/^/    /'

    echo ""
    echo "Config verification FAILED: $CONFIG"
    exit 1
fi

echo "    config ok"
