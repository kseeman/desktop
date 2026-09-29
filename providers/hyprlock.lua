-- The lock screen.
--
-- No `start`: it is run on demand, by the lock binding and by hypridle.
local paths = require("lib.paths")

return {
    name = "hyprlock",

    fills = { "lock" },

    -- -c is not optional. Bare `hyprlock` reads ~/.config/hypr/hyprlock.conf,
    -- which is HyDE's and sources files that disappear with it. A lock screen
    -- built from a missing config is the one failure needing a TTY to escape.
    actions = {
        lock = "hyprlock -c " .. paths.desktop_file("hyprlock.conf"),
    },
}
