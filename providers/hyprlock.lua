-- The lock screen.
--
-- No `start`: it is run on demand, by the lock binding and by hypridle.
local paths = require("lib.paths")

return {
    name = "hyprlock",

    fills = { "lock" },

    -- The config is generated, so this points into the theme cache rather than
    -- at the repo. Nothing is lost if it is missing: hyprlock refuses to start
    -- without a config, so the failure is "no lock" rather than a broken lock
    -- screen you cannot dismiss.
    --
    -- -c is not optional either way. Bare `hyprlock` reads
    -- ~/.config/hypr/hyprlock.conf, which is HyDE's and sources files that
    -- disappear with it.
    actions = {
        lock = "hyprlock -c " .. paths.theme .. "hyprlock.conf",
    },

    templates = {
        { src = "hyprlock.conf.in", out = "$THEME_DIR/hyprlock.conf" },
    },
}
