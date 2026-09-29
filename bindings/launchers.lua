-- Launching things: the application launcher and the clipboard.
--
-- Both are surfaces of the bar rather than separate programs. That is why rofi
-- was dropped here: the launcher is drawn by the same process, in the same
-- palette, with the same motion, so there is no second theme file to keep in
-- step with lib/palette.lua.
--
-- The cost, stated plainly: nothing launches while quickshell is dead. That is
-- a real single point of failure, and it is the trade that was chosen.
local mod = "SUPER"

local PILL = os.getenv("HOME") .. "/.dotfiles/os/linux/desktop/quickshell/pill"

-- The instance is addressed by the config path it was started with, which is
-- what startup.lua passes to `quickshell -p`. Upstream uses `qs -c pill`, which
-- only resolves a config installed under ~/.config/quickshell; this one is read
-- out of the repo, so it is addressed by path.
--
-- **The monitor is looked up rather than left empty, and that is not caution.**
-- Passing "" makes the pill fall back to Quickshell's Hyprland.focusedMonitor,
-- which is populated from the focusedmon event and so is null until focus has
-- *changed* at least once. Hyprland itself reports the monitor as focused the
-- whole time, so nothing looks wrong -- the surface simply never opens, and it
-- fails exactly when the desktop is freshest: right after login, before focus
-- has moved. Measured: with "" nothing renders; with the name it opens.
--
-- Toggling is free. Asking for a surface that is already open closes it, which
-- is what the `pkill -x rofi ||` prefix used to buy.
local function surface(name)
    return hl.dsp.exec_cmd(
        "qs -p " .. PILL .. " ipc call pill " .. name
            .. ' "$(hyprctl activeworkspace -j | jq -r .monitor)"'
    )
end

hl.bind(mod .. " + SPACE", surface("launcher"), { desc = "launcher" })

-- cliphist still stores the history -- see startup.lua, which runs the two
-- `cliphist store` watchers. The pill only reads it. Its own wl-paste watcher
-- is `--watch echo x`, a change notification telling it to re-read the list,
-- so it does not replace those and they are not duplicates.
hl.bind(mod .. " + V", surface("clipboard"), { desc = "clipboard" })

-- Deleting an entry is done from inside that surface, so the SHIFT+V variant
-- rofi needed is gone.
