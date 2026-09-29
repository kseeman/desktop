-- Ricelin's Quickshell pill.
--
-- Nine roles in one process, which is the thing to know before swapping it:
-- "replace the bar" here means finding providers for the launcher, clipboard,
-- notifications, wallpaper, tray and the rest as well.
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
        "wallpaper",
        "tray",
        "media",
        "audio",
    },

    start = "quickshell -p " .. PILL,

    -- Only the roles something binds a key to need an action. The rest are
    -- filled by virtue of the process running.
    actions = {
        launcher = surface("launcher"),
        clipboard = surface("clipboard"),
        power = surface("power"),
    },
}
