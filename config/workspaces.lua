-- Workspace behaviour.
--
-- Which workspace lives on which monitor is NOT here. Those rules name physical
-- outputs, so they belong in ~/.config/dotfiles/hypr/local.lua with the
-- monitors themselves -- the same reason the repo excludes workspaces.conf and
-- monitors.conf. Without them workspaces land wherever Hyprland decides, which
-- is the kind of thing that quietly breaks years of muscle memory.
hl.config({
    binds = {
        -- Pressing the current workspace's key again returns to the previous
        -- one, so the same key toggles rather than doing nothing.
        workspace_back_and_forth = true,

        -- Moving focus off the edge of a monitor crosses to the next one
        -- instead of stopping.
        window_direction_monitor_fallback = true,
    },
})
