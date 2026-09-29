-- Window management.
local mod = "SUPER"

-- Repeating, so holding a resize or move key keeps going.
local HELD = { repeating = true }

-- hyde-shell dontkillsteam refused to close Steam's tray window, which closes
-- to tray rather than quitting. A plain close is what it wrapped.
hl.bind(mod .. " + Q", hl.dsp.window.close(), { desc = "close window" })
hl.bind("ALT + F4", hl.dsp.window.close(), { desc = "close window" })

hl.bind(mod .. " + W", hl.dsp.window.float({ action = "toggle" }), { desc = "toggle floating" })
hl.bind("SHIFT + F11", hl.dsp.window.fullscreen(), { desc = "toggle fullscreen" })
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.pin(), { desc = "pin window" })
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"), { desc = "toggle split" })

-- Groups stack windows into one frame with a tab bar.
hl.bind(mod .. " + G", hl.dsp.group.toggle(), { desc = "toggle group" })
hl.bind(mod .. " + CONTROL + H", hl.dsp.group.prev(), { desc = "group: previous" })
hl.bind(mod .. " + CONTROL + L", hl.dsp.group.next(), { desc = "group: next" })

-- The key name and the direction argument look alike and are not the same
-- thing. Hyprland matches keys against xkbcommon keysyms, where the arrows are
-- capitalised; the dispatcher takes a direction, which is lower case. Using one
-- string for both bound four keys that do not exist, silently.
local DIRECTIONS = {
    { key = "Left", dir = "left" },
    { key = "Right", dir = "right" },
    { key = "Up", dir = "up" },
    { key = "Down", dir = "down" },
}

for _, d in ipairs(DIRECTIONS) do
    hl.bind(mod .. " + " .. d.key, hl.dsp.focus({ direction = d.dir }), { desc = "focus " .. d.dir })
end

hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { desc = "cycle focus" })

-- Resize in 30px steps.
local RESIZE = {
    left = { -30, 0 },
    right = { 30, 0 },
    up = { 0, -30 },
    down = { 0, 30 },
}

for _, d in ipairs(DIRECTIONS) do
    local delta = RESIZE[d.dir]

    -- relative is what makes these a nudge rather than a size. Without it the
    -- pair is read as an absolute width and height, so "grow 30 wider" asks
    -- for a window 30 by 0 and the dispatcher refuses with "Invalid size".
    --
    -- The bindings were dead until the keysym fix, so this had never once run:
    -- a wrong call sitting behind a key that could not be pressed.
    hl.bind(
        mod .. " + SHIFT + " .. d.key,
        hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }),
        { desc = "resize " .. d.dir, repeating = true }
    )
end

-- Move the window itself. In the source this tried a pixel move and fell back
-- to a tiling move; a tiled window cannot be nudged by pixels, so the direction
-- form is what actually ran nearly always.
for _, d in ipairs(DIRECTIONS) do
    hl.bind(
        mod .. " + SHIFT + CONTROL + " .. d.key,
        hl.dsp.window.move({ direction = d.dir }),
        { desc = "move window " .. d.dir, repeating = true }
    )
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, desc = "drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "resize window" })
hl.bind(mod .. " + Z", hl.dsp.window.drag(), { mouse = true, desc = "hold to move window" })
hl.bind(mod .. " + X", hl.dsp.window.resize(), { mouse = true, desc = "hold to resize window" })
