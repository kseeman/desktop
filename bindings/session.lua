-- Locking and leaving.
--
-- Both name roles rather than programs. The lock command and the logout menu's
-- arguments live in their providers; lib/roles.lua says which provider holds
-- each. Only the last binding names a behaviour rather than a component,
-- because ending the session is the compositor's own job.
local roles = require("lib.roles")

local mod = "SUPER"

hl.bind(mod .. " + L", roles.action("lock"), { desc = "lock screen" })

hl.bind("CONTROL + ALT + Delete", roles.action("power"), { desc = "logout menu" })

-- Ends the session outright, with no menu in the way.
hl.bind(mod .. " + Delete", hl.dsp.exit(), { desc = "exit hyprland" })
