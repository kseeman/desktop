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
-- P4 fills this in. It stays near-empty for P1 so the first login into this
-- session is a compositor and a terminal, with nothing else to go wrong.
hl.on("hyprland.start", function()
    -- A polkit agent, or nothing that needs authorisation will work.
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)
