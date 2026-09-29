-- Rounding, blur and shadow. P6 replaces the colours here with generated ones;
-- structure stays in this file so regenerating a palette never rewrites layout.
hl.config({
    decoration = {
        rounding = 10,

        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            ignore_opacity = true,
            xray = false,
        },

        -- Off deliberately: the reference design is flat, and the gaps do the
        -- separating that a shadow otherwise would.
        shadow = {
            enabled = false,
        },
    },
})
