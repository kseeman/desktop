-- Workspace rules. Monitor assignment is deliberately absent: it names physical
-- outputs, which differ per machine, and nwg-displays regenerates monitors.lua
-- whenever displays are rearranged. Same reasoning that keeps monitors.conf and
-- workspaces.conf out of HYPR_USER_CONFIGS.
hl.config({
    binds = {
        workspace_back_and_forth = true,
    },
})
