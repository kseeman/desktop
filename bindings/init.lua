-- Keybindings.
--
-- P3 ports all 115. This file carries only what makes the session usable and,
-- more importantly, escapable: a terminal, a window close, and an exit. A
-- session you cannot get out of without a TTY is not a safe thing to log into.
--
-- Descriptions are filled in throughout because hl.bind takes them natively and
-- `hyprctl binds -j` can then drive a cheatsheet, the way tmux's `list-keys -N`
-- does for the tmux one.
local mod = "SUPER"

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"), { desc = "terminal" })

-- The launcher. Until this existed the only way to start anything was a
-- terminal, which makes the session escapable but not usable -- a distinction
-- worth keeping in mind for the rest of the bindings.
--
-- rofi is unstyled here and will look nothing like the rest of the desktop
-- until it reads a generated theme. That is P5/P6; a plain launcher now beats a
-- styled one later.
hl.bind(mod .. " + R", hl.dsp.exec_cmd("rofi -show drun"), { desc = "launcher" })
hl.bind(mod .. " + Q", hl.dsp.window.close(), { desc = "close window" })
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "toggle floating" })
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"), { desc = "toggle split" })

-- Deliberately bound from the first boot: without it, leaving this session
-- means switching to a TTY and killing the compositor.
hl.bind(mod .. " + SHIFT + M", hl.dsp.exit(), { desc = "exit hyprland" })

for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }), { desc = "focus " .. dir })
end

for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { desc = "workspace " .. i })
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { desc = "move to workspace " .. i })
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "resize window" })
