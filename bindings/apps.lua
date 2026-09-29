-- Applications.
--
-- The source reached these through $TERMINAL/$BROWSER/$EDITOR, which expanded
-- to `hyde-shell open --fall <app> <category>`: a launcher that tried an
-- application and fell back to whatever handled the category. The fallback is
-- dropped and the applications named directly -- a fallback chain is worth
-- having when a config ships to strangers, and this one ships to one machine.
--
-- These are the machine's actual defaults rather than HyDE's: brave is the
-- registered web browser here, not firefox.
local mod = "SUPER"

local TERMINAL = "kitty"
local BROWSER = "brave"
local EDITOR = "code"
local FILES = "dolphin"

hl.bind(mod .. " + T", hl.dsp.exec_cmd(TERMINAL), { desc = "terminal" })
hl.bind(mod .. " + B", hl.dsp.exec_cmd(BROWSER), { desc = "web browser" })
hl.bind(mod .. " + C", hl.dsp.exec_cmd(EDITOR), { desc = "editor" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(FILES), { desc = "file manager" })

-- hyde-shell system.monitor opened whatever HyDE considered one. btop is
-- installed and is the one worth having in a terminal.
hl.bind(
    "CONTROL + SHIFT + Escape",
    hl.dsp.exec_cmd(TERMINAL .. " -e btop"),
    { desc = "system monitor" }
)

-- Not ported: the pyprland dropdown terminal on SUPER+ALT+T. pypr is not
-- installed, so there is nothing to toggle.
