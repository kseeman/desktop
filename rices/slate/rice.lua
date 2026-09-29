return {
    description = "Flat, tight and quick, in near-neutral slate",

    -- No providers block: every role keeps its default, which is what a rice
    -- that only changes how things look should say. Switching to this one and
    -- back needs no re-login for exactly that reason.

    look = {
        gaps_in = 2,
        gaps_out = 4,
        border_size = 1,
        rounding = 0,

        -- Off: without rounding there is no soft edge for a blurred backdrop to
        -- sit against, and the flat surfaces are the point here.
        blur = false,

        -- Faster than violet's 4.2. A minimal look that moves slowly reads as
        -- sluggish rather than calm, because there is no depth to justify it.
        motion_speed = 2.6,
    },
}
