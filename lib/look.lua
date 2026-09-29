-- -----------------------------------------------------------------------------
-- Look
-- -----------------------------------------------------------------------------
--
-- Everything a rice changes that is not a colour: gaps, rounding, borders,
-- blur, and how fast the desktop moves.
--
-- Separate from lib/palette.lua because these reach Hyprland directly rather
-- than through a generated file -- there is nothing to render, the compositor
-- reads Lua. Same arrangement though: the rice supplies what it cares about and
-- the defaults below catch the rest.
--
-- These defaults are a working desktop rather than a floor, unlike the
-- palette\'s grey. A missing colour should look wrong so it gets noticed; a
-- missing gap size has no such tell and may as well be sensible.
local rice = require("lib.rice")

local DEFAULT = {
    gaps_in = 3,
    gaps_out = 8,
    border_size = 2,
    rounding = 10,
    blur = true,

    -- Hyprland\'s units, where 4.2 is roughly 420ms.
    motion_speed = 4.2,

    -- How a wallpaper meets a screen it does not share an aspect ratio with.
    --
    -- `fit` rather than awww\'s own `crop` default, because crop discards
    -- whatever does not fit and says nothing about it: on the 32:9 ultrawide
    -- here a 16:9 image silently loses half its height. fit keeps the whole
    -- image and pads the rest, which is the honest failure -- you can see that
    -- the image does not cover the screen, instead of wondering where the top
    -- of it went.
    --
    -- `crop` is still the better choice for a screen whose images mostly match
    -- it, and `wallpaper_gravity` then picks which part survives.
    wallpaper_fit = "fit",
    wallpaper_gravity = "center",

    -- What fills the space an image does not cover. Three forms:
    --
    --   "sampled"   the current image\'s own darkest surface, from the
    --               generated palette -- so the padding belongs to the picture
    --               rather than to the rice, and changes with it
    --   "<name>"    a palette token, e.g. "root" -- follows the active rice
    --   "#RRGGBB"   a literal
    --
    -- The literal is the one place a colour may be written outside
    -- lib/palette.lua. Padding is not part of the theme: it is a property of
    -- how one image meets one screen, and the common want -- plain black behind
    -- a mostly-black image -- is not a palette colour and should not become one.
    wallpaper_fill = "sampled",
}

return setmetatable(rice.look, { __index = DEFAULT })
