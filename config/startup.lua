-- Autostart.
--
-- Everything here sits inside hl.on("hyprland.start", ...) and that placement
-- is not stylistic. --verify-config does not start a compositor, but a Lua
-- config is a Lua program and verifying it runs that program: measured on
-- 0.56.2, a top-level hl.exec_cmd runs and launches its application, while the
-- same call in this callback does not. Without that split, verifying a config
-- -- in the installer, or a pre-commit hook -- would start the whole autostart
-- set every time.
--
-- Not started here, with reasons:
--
--   xdg portal reset   HyDE restarts the portals so they see a complete
--                      environment. uwsm exports it and systemd activates them;
--                      both portals were confirmed active in this session
--                      without any help, so the reset is not carried over.
--   dunst              the pill is the notification server now. It claims
--                      org.freedesktop.Notifications at startup, and only one
--                      process may own that name, so dunst is never activated
--                      while the pill holds it -- no masking required. If the
--                      pill dies, the next notification activates dunst, which
--                      is a fallback worth keeping rather than a conflict.
--   battery notify     this machine is a desktop.
--   nm-applet,         the pill has its own wifi and bluetooth surfaces, and a
--   blueman-applet     tray for everything else. These would duplicate it.
--   waybar, wallpaper  the pill replaces both: it is the bar, and it sets the
--                      wallpaper itself from Flags.wallpaperDir.
local paths = require("lib.paths")
local roles = require("lib.roles")

local DESKTOP = paths.desktop

hl.on("hyprland.start", function()
    -- Generate the configs that carry colours, before anything that reads one.
    -- The installer does this too; repeating it at login is what makes a
    -- palette edit reach every consumer without running the installer, and it
    -- costs milliseconds.
    --
    -- First deliberately: hypridle is started below and locks on a timer, and
    -- the lock screen is one of the generated files.
    hl.exec_cmd("lua " .. DESKTOP .. "render-theme.lua")

    -- Authentication prompts. Without an agent, anything asking for a password
    -- fails silently rather than asking.
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Clipboard history, which is what SUPER+V reads. Two watchers because
    -- cliphist stores text and images through separate wl-paste invocations.
    -- History only exists from when these start, so a fresh session's clipboard
    -- is empty until something is copied.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Idle locking, from this repo's config rather than the HyDE one that calls
    -- hyde-shell.
    hl.exec_cmd("hypridle -c " .. DESKTOP .. "hypridle.conf")

    -- Blue light filter.
    hl.exec_cmd("hyprsunset")

    -- Removable media. Kept while the tray applets are not, because udiskie
    -- mounts and notifies whether or not anything is watching a tray.
    hl.exec_cmd("udiskie --no-automount --smart-tray")

    -- 1Password's SSH agent signs this repo's commits and does not survive a
    -- logout, which blocked three commits during P1 and P2 -- each needing it
    -- started by hand. --silent starts it to the tray rather than opening a
    -- window over whatever is already there.
    hl.exec_cmd("1password --silent")

    -- Whatever currently fills the desktop's roles -- the bar, the launcher,
    -- notifications, the wallpaper. One command per provider rather than per
    -- role, since the pill alone holds eight of them.
    --
    -- Nothing here names a component, so swapping one is an edit in
    -- lib/roles.lua and this loop keeps working. Providers that are run on
    -- demand rather than kept alive, like the lock screen, declare no start
    -- command and are simply absent from this list.
    --
    -- Colours reach them through generated files rather than through here:
    -- quickshell/apply-palette.sh writes the pill's from lib/palette.lua, and
    -- the pill watches it, so a theme change repaints without a restart.
    for _, command in ipairs(roles.start_commands()) do
        hl.exec_cmd(command)
    end
end)
