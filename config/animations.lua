-- Animations.
--
-- One curve and one speed for every leaf, which is the whole point. The
-- compositor and the shell have to animate identically or the desktop reads as
-- two programs sharing a screen: a window opening at one rate beside a panel
-- sliding at another is what makes a setup feel assembled rather than designed.
--
-- MOTION_SPEED is in Hyprland's units, where 4.2 is roughly 420ms. When P5
-- brings up the shell, its transition duration and easing must be set from
-- these same two values -- if they drift apart, this file is the one that is
-- wrong, because the shell is what the eye follows.
local MOTION = "morph"
local MOTION_SPEED = require("lib.look").motion_speed

hl.config({ animations = { enabled = true } })

-- cubic-bezier(0.16, 1, 0.3, 1): fast departure, long settle. The long tail is
-- what reads as weight; a symmetric curve at the same duration feels abrupt.
hl.curve(MOTION, { type = "bezier", points = { { 0.16, 1.00 }, { 0.30, 1.00 } } })

-- Style is per-leaf because it says what moves, not how fast. Speed and curve
-- stay uniform.
local leaves = {
    { leaf = "global" },
    { leaf = "windows" },
    { leaf = "windowsIn", style = "popin 92%" },
    { leaf = "windowsOut", style = "popin 92%" },
    { leaf = "border" },
    { leaf = "fade" },
    { leaf = "fadeIn" },
    { leaf = "fadeOut" },
    { leaf = "layers", style = "popin 90%" },
    { leaf = "fadeLayersIn" },
    { leaf = "fadeLayersOut" },
    { leaf = "workspaces", style = "slide" },
}

for _, animation in ipairs(leaves) do
    hl.animation({
        leaf = animation.leaf,
        enabled = true,
        speed = MOTION_SPEED,
        bezier = MOTION,
        style = animation.style,
    })
end
