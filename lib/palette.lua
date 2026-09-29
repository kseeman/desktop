-- -----------------------------------------------------------------------------
-- Palette
-- -----------------------------------------------------------------------------
--
-- The one place a colour is written down. Every module reads from here and no
-- config file contains a hex literal, which is what makes the scheme swappable
-- later without touching anything that uses it.
--
-- Right now this returns fixed values. At the point the theme engine lands it
-- loads generated data instead and falls back to these, and not one consumer
-- changes -- only the body of this file:
--
--   local ok, generated = pcall(dofile, cache .. "/palette.lua")
--   local M = setmetatable(ok and generated or {}, { __index = FALLBACK })
--
-- Those fallback values are a floor, not a theme. A missing or half-written
-- cache should give a dull desktop, never an unstartable session -- a config
-- that errors here takes the login with it.
--
-- The same discipline applies per consumer as each arrives: waybar gets an
-- @define-color block, rofi a `*` block, kitty a single included file. That is
-- already how os/linux/hyde-themes/Custom/{waybar,rofi,kitty}.theme are
-- written, so the pattern is proven here rather than invented.

local M = {}

-- -----------------------------------------------------------------------------
-- Values
-- -----------------------------------------------------------------------------

-- A single-hue tonal ramp: chroma and lightness rise together, which is the
-- shape Material You produces and therefore what matugen will generate into
-- these same names.
--
-- The text is deliberately a desaturated grey rather than a tinted one. Colour
-- lives in the surfaces; foreground that carries the hue is what makes a dark
-- scheme hard to read, and it is how the previous theme ended up with red,
-- green and yellow nearly indistinguishable.

M.root = "#120D1D" -- behind everything: the gaps between windows
M.base = "#1F1829" -- ordinary surface
M.raised = "#322948" -- a surface above the base
M.overlay = "#453852" -- popups, menus
M.muted = "#595162" -- borders and dividers, inactive chrome

M.accent = "#6E5E8C" -- focus, selection, the active border
M.accent_deep = "#594583" -- the accent where it needs more weight

M.bar = "#18151A" -- panel ground, near black and barely warm

M.fg = "#B5B0B1" -- primary text
M.fg_bright = "#E4E1E2" -- the brightest text, for the one thing being read
M.fg_muted = "#A79EA3" -- between primary and secondary: icons, inactive ticks
M.fg_dim = "#8F7D86" -- secondary text, inactive labels

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
