return {
    description = "Ricelin's pill in a violet tonal ramp",

    -- No providers block. This rice is the one the defaults in lib/roles.lua
    -- were written from, and it used to restate the whole set here on the
    -- grounds that seeing it once was worth more than brevity.
    --
    -- It is not: a restated default is a second copy that drifts, and this one
    -- did. Pointing the wallpaper role at awww in lib/roles.lua changed nothing
    -- while this block still pinned it to the pill -- the overriding was
    -- working exactly as designed, which is what made it hard to see. Naming
    -- only what a rice actually changes is the whole point of the table being
    -- partial.

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

        icon_theme = "Tela-circle-purple",
    },
}
