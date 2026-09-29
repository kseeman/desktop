-- Compositor behaviour that belongs to no other module.
hl.config({
    misc = {
        -- Hyprland's own wallpaper and splash. Off because this desktop sets
        -- its own, and because the splash has been implicated in a crash when
        -- a monitor is reconfigured while it would draw.
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,

        -- Variable refresh rate off. DP-1 is a 239.76Hz panel driven from an
        -- NVIDIA card, where VRR and a fixed high refresh do not mix well.
        vrr = 0,

        -- How many missed pings before a window is called unresponsive. The
        -- default is impatient enough to flag applications that are merely
        -- busy.
        anr_missed_pings = 5,

        -- Lets the lock screen come back after a crash instead of leaving the
        -- session unlocked behind a dead locker.
        allow_session_lock_restore = true,
    },

    -- XWayland applications render at scale 1 and are upscaled by the
    -- compositor. Without it they are blurry on a mixed-DPI setup, which this
    -- is: 5120x1440 beside 3840x2160.
    xwayland = {
        force_zero_scaling = true,
    },
})
