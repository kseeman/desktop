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
}

return setmetatable(rice.look, { __index = DEFAULT })
