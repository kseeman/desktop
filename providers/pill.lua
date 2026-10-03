-- Ricelin's Quickshell pill.
--
-- Nine roles in one process, which is the thing to know before swapping it:
-- "replace the bar" here means finding providers for the launcher, clipboard,
-- notifications, tray and the rest as well.
--
-- Not the wallpaper, despite owning the picker for it: see providers/awww.lua.
local paths = require("lib.paths")

local PILL = paths.desktop_file("quickshell/pill")

-- The instance is addressed by the config path it was started with. Upstream
-- uses `qs -c pill`, which only resolves a config installed under
-- ~/.config/quickshell; this one is read out of the repo.
--
-- The monitor is looked up rather than passed empty: toggleSurface falls back
-- to Quickshell's Hyprland.focusedMonitor for an empty string, and that is
-- populated from the focusedmon event, so it is null until focus has *changed*
-- once. The surface then silently never opens -- worst right after login.
local function surface(name)
    return "qs -p " .. PILL .. " ipc call pill " .. name
        .. ' "$(hyprctl activeworkspace -j | jq -r .monitor)"'
end

return {
    name = "pill",

    fills = {
        "bar",
        "launcher",
        "clipboard",
        "power",
        "notifications",
        "tray",
        "media",
        "audio",
        "gamemode",
    },

    start = "quickshell -p " .. PILL,

    -- The pill watches this file and repaints without a restart, so a theme
    -- change needs nothing else. Its path is fixed by the vendored code, which
    -- is why this one output is not under $THEME_DIR.
    --
    -- The template lives beside the pill rather than inside it: the vendored
    -- tree stays a verbatim copy, and a file of ours in there would be one more
    -- thing to re-apply if it is ever re-copied from upstream.
    templates = {
        { src = "quickshell/pill-colors.json.in", out = "$XDG_CACHE_HOME/ricelin/colors.json" },
    },

    -- Only the roles something binds a key to need an action. The rest are
    -- filled by virtue of the process running.
    actions = {
        launcher = surface("launcher"),
        clipboard = surface("clipboard"),
        power = surface("power"),

        -- Not a surface: gameMode flips Flags.gameMode, which the pill's own
        -- GameMode.qml watches and answers by running gamemode.sh. Going
        -- through the pill rather than calling the script keeps its chip, its
        -- bar height and the compositor in step -- the script alone would
        -- strip the desktop while the bar still thought it was off.
        gamemode = surface("gameMode"),
    },
}
