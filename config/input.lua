-- Keyboard and pointer. kb_layout is stated rather than left to the default so
-- a session started from a bare TTY behaves the same as one from SDDM.
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,

        -- Flat, not adaptive: pointer distance tracks hand distance, which is
        -- what makes a large ultrawide predictable to cross.
        accel_profile = "flat",

        numlock_by_default = true,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Three fingers horizontally switches workspace; pinch toggles floating. Both
-- are Hyprland defaults in spirit but have to be declared to exist.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "pinchin", action = "float" })
hl.gesture({ fingers = 3, direction = "pinchout", action = "float" })
