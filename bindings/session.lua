-- Locking and leaving.
local mod = "SUPER"

-- hyde-shell lock-session wrapped hyprlock with bookkeeping this desktop does
-- not have. hyprlock is what it ran.
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"), { desc = "lock screen" })

-- wlogout is the menu hyde-shell logoutlaunch opened.
hl.bind("CONTROL + ALT + Delete", hl.dsp.exec_cmd("wlogout"), { desc = "logout menu" })

-- Ends the session outright, with no menu in the way.
hl.bind(mod .. " + Delete", hl.dsp.exit(), { desc = "exit hyprland" })
