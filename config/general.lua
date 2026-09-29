-- Gaps, borders and layout.
local palette = require("lib.palette")

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        layout = "dwindle",

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
})
