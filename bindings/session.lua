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

-- wlogout is the menu hyde-shell logoutlaunch opened. Its layout and styling
-- come from this repo: the shipped ~/.config/wlogout/layout_1 calls
-- `hyde-shell logout` and `lockscreen.sh`, so three of its six buttons stop
-- working when HyDE goes -- a menu that opens and does nothing.
local DESKTOP = os.getenv("HOME") .. "/.dotfiles/os/linux/desktop"

hl.bind(
    "CONTROL + ALT + Delete",
    hl.dsp.exec_cmd("wlogout -l " .. DESKTOP .. "/wlogout/layout -C " .. DESKTOP .. "/wlogout/style.css"),
    { desc = "logout menu" }
)

-- Ends the session outright, with no menu in the way.
hl.bind(mod .. " + Delete", hl.dsp.exit(), { desc = "exit hyprland" })
