-- Launching things: the application launcher and the clipboard.
--
-- Each of these replaced a `hyde-shell <name>` wrapper. Most of those wrappers
-- were a few lines around a tool that is already installed, so the tool is
-- called directly and the wrapper is not reimplemented.
local mod = "SUPER"

-- `pkill -x rofi ||` is a toggle, not tidiness: pressing the same key while
-- rofi is open closes it instead of stacking a second instance behind the
-- first. Ported from the source, where every rofi binding carries it.
local function toggle_rofi(command)
    return hl.dsp.exec_cmd("pkill -x rofi || " .. command)
end

hl.bind(mod .. " + R", toggle_rofi("rofi -show drun"), { desc = "launcher" })

-- cliphist keeps the history; rofi picks from it; wl-copy puts the choice back
-- on the clipboard. `--no-custom` stops a typo being pasted as if it were an
-- entry, and `-i` makes the search case-insensitive.
local CLIPHIST = "cliphist list | rofi -dmenu -i --no-custom -p clipboard"
    .. " | cliphist decode | wl-copy"

hl.bind(mod .. " + V", toggle_rofi(CLIPHIST), { desc = "clipboard" })

-- Same list, but deleting rather than pasting.
hl.bind(
    mod .. " + SHIFT + V",
    toggle_rofi("cliphist list | rofi -dmenu -i -p 'clipboard: delete' | cliphist delete"),
    { desc = "clipboard: delete an entry" }
)
