-- The logout menu.
--
-- Active for the `power` role even though the pill also offers one, because
-- this is what CTRL+ALT+Delete has always opened here. Switching to the pill's
-- is a one-word edit in lib/roles.lua -- which is the point of all this.
local paths = require("lib.paths")

return {
    name = "wlogout",

    fills = { "power" },

    -- -b 5 puts all five buttons on one row. The default of three per row
    -- leaves an empty cell that still takes the button styling: a blank button
    -- that does nothing.
    -- The layout is static and read from the repo; the stylesheet is generated,
    -- so it comes from the theme cache.
    actions = {
        power = "wlogout -b 5 -l " .. paths.desktop_file("wlogout/layout")
            .. " -C " .. paths.theme .. "wlogout.css",
    },

    templates = {
        { src = "wlogout/style.css.in", out = "$THEME_DIR/wlogout.css" },
    },
}
