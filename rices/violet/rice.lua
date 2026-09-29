return {
    description = "Ricelin's pill in a violet tonal ramp",

    -- Role to provider. Partial on purpose: anything not named here keeps the
    -- default from lib/roles.lua, so a rice that only swaps the launcher says
    -- only that.
    --
    -- Spelled out in full here because this is the rice the defaults were
    -- written from, and seeing the whole set once is worth more than brevity.
    providers = {
        bar = "pill",
        launcher = "pill",
        clipboard = "pill",
        notifications = "pill",
        wallpaper = "pill",
        tray = "pill",
        media = "pill",
        audio = "pill",

        lock = "hyprlock",
        power = "wlogout",
    },

    -- Everything a look is beyond colour.
    look = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        rounding = 10,
        blur = true,

        -- One curve and one speed for the whole desktop -- the insight taken
        -- from the reference design. Raising this makes everything faster
        -- together rather than drifting out of step.
        motion_speed = 4.2,
    },
}
