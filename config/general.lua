-- Gaps, borders and layout. Values are placeholders until P2 ports the real
-- ones; what matters here is that the module loads and the keys are valid.
hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        resize_on_border = true,
        layout = "dwindle",
    },

    dwindle = {
        preserve_split = true,
    },
})
