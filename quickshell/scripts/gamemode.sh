#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# gamemode.sh
# -----------------------------------------------------------------------------
#
# Strips the desktop's eye-candy while gaming, and puts it back.
#
#   gamemode.sh on     no gaps, no rounding, no blur, no shadows, no
#                      animations, nothing transparent -- a 1px border stays
#   gamemode.sh off    back to the rice
#
# Called by the pill: Singletons/GameMode.qml runs this whenever
# `Flags.gameMode` changes, so the mixer chip, the keybind and IPC all arrive
# here. Not meant to be run by hand -- doing so leaves the pill's own flag out
# of step with the compositor.
#
# -----------------------------------------------------------------------------
# hyprctl keyword does not work here
# -----------------------------------------------------------------------------
#
# This desktop's config is Lua, and Hyprland answers `hyprctl keyword` with
#
#     keyword can't work with non-legacy parsers. Use eval.
#
# so every setting below goes through `hyprctl eval`, which runs Lua against the
# live config -- the same `hl.config` and `hl.window_rule` the config files use.
#
# -----------------------------------------------------------------------------
# Off is a reload, not a restore
# -----------------------------------------------------------------------------
#
# Leaving game mode re-reads the config rather than putting remembered values
# back. The config is the source of truth for every one of these settings, so
# reading it again is exactly right, and there is no snapshot to be wrong -- a
# pill restart mid-game, a rice switch, an edit to look.lua all resolve
# correctly because nothing was remembered in the first place.
#
# `hyprctl reload` re-reads the config without re-running autostart, which is
# what makes this safe to do at any moment.

set -euo pipefail

usage() {
    echo "usage: gamemode.sh on|off" >&2
    exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
    on)
        # What HyDE's workflows/gaming.conf did, recovered from a snapshot --
        # shadows, blur, rounding, gaps and animations off, everything opaque,
        # and a 1px border kept so windows are still told apart.
        #
        # Everything in one eval: a half-applied strip is a visibly broken
        # desktop, and Hyprland applies the table atomically.
        hyprctl eval '
            hl.config({
                general = { gaps_in = 0, gaps_out = 0, border_size = 1 },
                decoration = {
                    rounding = 0,
                    active_opacity = 1.0,
                    inactive_opacity = 1.0,
                    fullscreen_opacity = 1.0,
                    shadow = { enabled = false },
                    -- xray with blur off is what HyDE set: it stops any layer
                    -- still asking for blur costing a pass over the wallpaper.
                    blur = { enabled = false, xray = true },
                },
                animations = { enabled = false },
            })
        ' > /dev/null

        # The per-class opacity rules in config/rules.lua outrank
        # decoration:active_opacity, so turning that up is not enough on its
        # own -- kitty and the rest stay translucent. `opaque` is what HyDE
        # used and is the stronger statement: it drops the alpha of the
        # window rather than setting a value another rule can outrank.
        hyprctl eval '
            hl.window_rule({
                name = "gamemode-opaque",
                match = { class = ".*" },
                opaque = true,
            })
        ' > /dev/null

        # The bar keeps its own blur and animation otherwise, which is a
        # compositor pass per frame over a layer that is mostly static.
        hyprctl eval '
            hl.layer_rule({
                name = "gamemode-layers",
                match = { namespace = "^(pill|quickshell)$" },
                blur = false,
                no_anim = true,
            })
        ' > /dev/null
        ;;

    off)
        hyprctl reload > /dev/null
        ;;

    *) usage ;;
esac
