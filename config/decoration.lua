-- Rounding, blur and shadow. P6 replaces the colours here with generated ones;
-- structure stays in this file so regenerating a palette never rewrites layout.
hl.config({
    decoration = {
        rounding = 10,

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
            enabled = true,
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
