-- Violet: a single-hue tonal ramp.
--
-- Chroma and lightness rise together, which is the shape Material You produces
-- and therefore what matugen will generate into these same names.
--
-- The text is deliberately a desaturated grey rather than a tinted one. Colour
-- lives in the surfaces; foreground carrying the hue is what makes a dark
-- scheme hard to read, and it is how the previous theme ended up with red,
-- green and yellow nearly indistinguishable.
return {
    root = "#120D1D", -- behind everything: the gaps between windows
    base = "#1F1829", -- ordinary surface
    raised = "#322948", -- a surface above the base
    overlay = "#453852", -- popups, menus
    muted = "#595162", -- borders and dividers, inactive chrome

    accent = "#6E5E8C", -- focus, selection, the active border
    accent_deep = "#594583", -- the accent where it needs more weight

    bar = "#18151A", -- panel ground, near black and barely warm

    fg = "#B5B0B1", -- primary text
    fg_bright = "#E4E1E2", -- the brightest text, for the one thing being read
    fg_muted = "#A79EA3", -- between primary and secondary: icons, inactive ticks
    fg_dim = "#8F7D86", -- secondary text, inactive labels
}
