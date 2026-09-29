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

# Which calls execute the moment the config is read, measured on 0.56.2:
#
#   hl.exec_cmd(...)                 runs
#   os.execute(...) / io.popen(...)  runs
#   hl.dispatch(hl.dsp.exec_cmd(..)) runs
#   an exec in a function called at the top level    runs
#   hl.dsp.exec_cmd(...) passed to hl.bind           does NOT -- it builds a
#                                                    dispatcher, so bindings are
#                                                    safe and must not be flagged
#   a Lua function passed to hl.bind                 does NOT -- it is stored,
#                                                    not called, so an exec in a
#                                                    keybind body is deferred
#   anything inside hl.on("hyprland.start", ...)     does NOT
#
# The last three are why this is a per-file rule rather than a per-line one. An
# exec indented inside a top-level `for` still runs, and an exec reached through
# a function call cannot be spotted by grep at all -- so what is checked is
# whether a file that execs has somewhere to defer them to.
#
# Both hl.on("hyprland.start") and hl.bind defer, so either exempts a file. That
# exempts a bindings file wholesale, which is the point rather than a weakness:
# a keybind body is where a deferred exec belongs, and what this is looking for
# is an exec with nowhere to defer to at all.
#
# Note hl.dsp.exec_cmd does not contain the substring hl.exec_cmd, so the
# pattern below passes over every binding without needing to exclude it.
EXEC_PATTERN='hl\.exec_cmd|hl\.dispatch|os\.execute|io\.popen'

# Modules too, not just the entry point: every exec in this desktop lives in
# config/startup.lua, which a check that only read the file it was given would
# never have looked at.
exec_warnings=0

while IFS= read -r module; do
    grep -qE "$EXEC_PATTERN" "$module" 2> /dev/null || continue
    grep -qE 'hl\.on\("hyprland\.start"|hl\.bind\(' "$module" 2> /dev/null && continue

    if [[ $exec_warnings -eq 0 ]]; then
        echo "Warning: these run whenever the config is verified, not just at login:"
    fi

    grep -nE "$EXEC_PATTERN" "$module" | sed "s|^|    ${module#"$DESKTOP_DIR/"}:|"
    exec_warnings=$((exec_warnings + 1))
done < <(find "$(dirname "$CONFIG")" -name '*.lua' -type f 2> /dev/null | sort)

if [[ $exec_warnings -gt 0 ]]; then
    echo "    Move them inside hl.on(\"hyprland.start\", function() ... end),"
    echo "    which is not run by --verify-config."
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
