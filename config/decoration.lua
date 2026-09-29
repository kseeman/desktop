-- Rounding, blur and shadow. P6 replaces the colours here with generated ones;
-- structure stays in this file so regenerating a palette never rewrites layout.
local palette = require("lib.palette")
local look = require("lib.look")

hl.config({
    decoration = {
        rounding = look.rounding,

        -- Unfocused windows recede rather than just losing their border. This
        -- is most of why the desktop reads as focused-on-one-thing, and it is
        -- the setting people miss first when it is absent.
        active_opacity = 0.90,
        inactive_opacity = 0.75,
        fullscreen_opacity = 1.0,

        -- The special workspace is dimmed behind whatever it holds, so a
        -- scratchpad reads as layered over the desktop rather than replacing it.
        dim_special = 0.3,

        blur = {
            enabled = look.blur,
            size = 4,
            passes = 2,
            ignore_opacity = true,
            xray = false,

            -- Without this the special workspace shows an unblurred backdrop
            -- while everything around it is blurred.
            special = true,
        },

        -- Off deliberately: the reference design is flat, and the gaps do the
        -- separating that a shadow otherwise would.
        shadow = {
            enabled = false,
        },
    },
})

-- -----------------------------------------------------------------------------
-- Window groups
-- -----------------------------------------------------------------------------

-- Grouped windows share one frame and are switched by a tab bar. The bar is
-- worth styling rather than leaving default because it is the only chrome in
-- the desktop that carries text, so it is where an unreadable pairing shows up
-- first -- hence the active tab taking the accent and the inactive ones sitting
-- on a surface colour rather than a tint of it.
hl.config({
    group = {
        groupbar = {
            enabled = true,
            gradients = true,
            render_titles = true,

            font_weight_inactive = "normal",
            font_weight_active = "semibold",

            col = {
                active = palette.rgba(palette.accent, "ee"),
                inactive = palette.rgba(palette.base, "ee"),
                locked_active = palette.rgba(palette.accent_deep, "ee"),
                locked_inactive = palette.rgba(palette.root, "ee"),
            },

            text_color = palette.rgba(palette.fg, "ee"),
            text_color_inactive = palette.rgba(palette.fg_dim, "ee"),

            blur = true,
        },
    },
})
