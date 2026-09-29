-- Gaps, borders and layout.
local palette = require("lib.palette")
local look = require("lib.look")

hl.config({
    general = {
        gaps_in = look.gaps_in,
        gaps_out = look.gaps_out,
        border_size = look.border_size,
        resize_on_border = true,
        layout = "dwindle",

        -- Floating windows snap to each other and to edges.
        snap = {
            enabled = true,
        },

        col = {
            -- The focused window is the only thing wearing the accent, which
            -- is what makes it findable across two monitors without needing a
            -- thicker border.
            active_border = palette.rgb(palette.accent),
            inactive_border = palette.rgb(palette.muted),
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },
})
