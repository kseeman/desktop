-- The wallpaper.
--
-- A provider of its own rather than the pill, and that distinction is the whole
-- reason nothing put the wallpaper back at login. The pill is the *picker*: the
-- vendored Walls.qml reads `resolve` and `current` and applies when you choose
-- a thumb, and never otherwise. awww is what actually holds an image on the
-- background layer, and it needs starting.
--
-- The role being held by a process that did not do the job is what hid this --
-- `wallpaper = "pill"` looked filled, and the pill was indeed running.
--
-- Nothing is taken away from the pill: its picker surface is reached over IPC
-- rather than through roles.action, so it is unaffected by which provider holds
-- the role.
local paths = require("lib.paths")

return {
    name = "awww",

    fills = { "wallpaper" },

    -- `restore` starts the daemon as well, which is most of why this has a
    -- start command at all: awww-daemon restores its own per-output cache when
    -- it comes up, and nothing was bringing it up. The daemon used to be
    -- started lazily by `set`, so it existed only once something had already
    -- changed the wallpaper -- never at a fresh login.
    --
    -- The repo path rather than the ~/.config/hypr/scripts symlink the pill
    -- uses, so a config loaded from a worktree restores through its own copy of
    -- the script, like every other path here.
    start = "bash " .. paths.desktop_file("quickshell/scripts/wallpaper.sh") .. " restore",
}
