-- Keyboard and pointer. kb_layout is stated rather than left to the default so
-- a session started from a bare TTY behaves the same as one from SDDM.
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})
