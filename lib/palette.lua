-- -----------------------------------------------------------------------------
-- Palette
-- -----------------------------------------------------------------------------
--
-- The one place a colour is written down. Every module reads from here and no
-- config file contains a hex literal, which is what makes the scheme swappable
-- later without touching anything that uses it.
--
-- The values come from the active rice -- see lib/rice.lua. What is left here
-- is the floor underneath them.
--
-- **The fallback is deliberately not a theme.** It is a flat grey, so a rice
-- that fails to load gives a dull desktop that plainly looks wrong rather than
-- a plausible one that quietly is. A config that errors here would take the
-- login with it, so nothing errors; it just goes grey.
--
-- Keeping the floor drab also means it is never a second copy of a real
-- scheme's values, which would drift the moment that scheme changed.
local rice = require("lib.rice")

local FLOOR = {
    root = "#101010",
    base = "#1A1A1A",
    raised = "#262626",
    overlay = "#333333",
    muted = "#4D4D4D",

    accent = "#666666",
    accent_deep = "#555555",

    bar = "#141414",

    fg = "#C0C0C0",
    fg_bright = "#E8E8E8",
    fg_muted = "#A0A0A0",
    fg_dim = "#808080",
}

-- A generated palette, when the rice asks for one. Written by
-- quickshell/scripts/generate-palette.sh after a wallpaper change.
--
-- pcall because this file is produced by a script that can be interrupted
-- mid-write; a half-written palette should fall through to the floor rather
-- than stop the config parsing and take the login with it.
local generated

if rice.palette_from == "wallpaper" then
    local cache = os.getenv("XDG_CACHE_HOME") or (os.getenv("HOME") .. "/.cache")
    local ok, result = pcall(dofile, cache .. "/dotfiles/theme/palette-generated.lua")

    if ok and type(result) == "table" then
        generated = result
    end
end

-- Three layers, each falling through to the next: what the rice writes down,
-- what was derived from the wallpaper, and the floor.
--
-- The static values winning is what lets a rice derive most of a scheme and
-- still pin the one or two colours it actually cares about.
--
-- __index rather than a copy, so a rice defining only some names still gets the
-- rest rather than nil -- which would reach a config file as an empty string.
local beneath = setmetatable(generated or {}, { __index = FLOOR })

local M = setmetatable(rice.palette or {}, { __index = beneath })

-- -----------------------------------------------------------------------------
-- Formats
-- -----------------------------------------------------------------------------

-- Hyprland does not take CSS hex. It wants rgb(RRGGBB) or rgba(RRGGBBAA), so
-- the conversion lives here rather than in each module -- consumers that do
-- take hex (waybar, rofi, kitty) keep reading the values above directly.

local function bare(hex)
    return (hex:gsub("^#", ""))
end

--- @param hex string a "#RRGGBB" value from this table
--- @return string suitable for a Hyprland colour option
function M.rgb(hex)
    return "rgb(" .. bare(hex) .. ")"
end

--- @param hex string a "#RRGGBB" value from this table
--- @param alpha string two hex digits, e.g. "ee" for nearly opaque
--- @return string suitable for a Hyprland colour option
function M.rgba(hex, alpha)
    return "rgba(" .. bare(hex) .. alpha .. ")"
end

return M
