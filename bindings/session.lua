-- Locking and leaving.
local mod = "SUPER"

-- hyde-shell lock-session wrapped hyprlock with bookkeeping this desktop does
-- not have. hyprlock is what it ran.
--
-- -c is not optional: bare `hyprlock` reads ~/.config/hypr/hyprlock.conf, which
-- is HyDE's and sources files that disappear with it. A lock screen built from
-- a missing config is the one failure that needs a TTY to get out of.
local LOCK = "hyprlock -c " .. os.getenv("HOME") .. "/.dotfiles/os/linux/desktop/hyprlock.conf"

hl.bind(mod .. " + L", hl.dsp.exec_cmd(LOCK), { desc = "lock screen" })

-- wlogout is the menu hyde-shell logoutlaunch opened.
hl.bind("CONTROL + ALT + Delete", hl.dsp.exec_cmd("wlogout"), { desc = "logout menu" })

-- Ends the session outright, with no menu in the way.
hl.bind(mod .. " + Delete", hl.dsp.exit(), { desc = "exit hyprland" })
