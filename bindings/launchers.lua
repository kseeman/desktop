-- Launching things: the application launcher and the clipboard.
--
-- These name roles rather than programs, so whatever currently fills them
-- answers. Which one that is lives in lib/roles.lua; how it is invoked lives in
-- its provider. Nothing about quickshell appears here, which is the whole point
-- -- swapping the launcher should not mean editing keybindings.
--
-- Asking for a surface that is already open closes it, so toggling is free and
-- the `pkill -x rofi ||` prefix the old rofi bindings carried is not needed.
local roles = require("lib.roles")

local mod = "SUPER"

hl.bind(mod .. " + SPACE", roles.action("launcher"), { desc = "launcher" })

-- cliphist stores the history -- see startup.lua, which runs the two
-- `cliphist store` watchers. That is infrastructure rather than part of this
-- role: the store has to outlive any particular picker, and the pill only
-- reads it. Its own wl-paste watcher is `--watch echo x`, a change
-- notification telling it to re-read the list, not a second store.
hl.bind(mod .. " + V", roles.action("clipboard"), { desc = "clipboard" })
