-- Screenshots and the colour picker.
--
-- hyde-shell screenshot took a mode letter and dispatched to grimblast, which
-- HyDE vendors and which therefore disappears with it. hyprshot is packaged,
-- already installed, and covers three of the four modes directly; it saves to a
-- folder and copies to the clipboard in one step.
local mod = "SUPER"

-- Resolved in Lua rather than left to the shell, so the folder is the same one
-- whether or not XDG_PICTURES_DIR happens to be exported into the session.
local pictures = os.getenv("XDG_PICTURES_DIR") or (os.getenv("HOME") .. "/Pictures")
local SHOTS = pictures .. "/Screenshots"

local function hyprshot(args)
    return hl.dsp.exec_cmd("hyprshot -o '" .. SHOTS .. "' " .. args)
end

hl.bind(mod .. " + P", hyprshot("-m region"), { desc = "screenshot: region" })

-- Freezing first is what makes it possible to capture a menu or a hover state,
-- which vanish the moment a selection overlay takes the pointer.
hl.bind(mod .. " + CONTROL + P", hyprshot("-m region --freeze"), { desc = "screenshot: region, frozen" })

hl.bind(mod .. " + ALT + P", hyprshot("-m output"), { desc = "screenshot: this monitor" })

-- hyprshot has no every-monitor mode, so the whole layout goes through grim,
-- which captures all outputs when given no geometry. Saved and copied by hand
-- to match what the other three do.
hl.bind(
    "Print",
    hl.dsp.exec_cmd(
        "mkdir -p '" .. SHOTS .. "' && f=\"" .. SHOTS .. "/$(date +%Y-%m-%d-%H%M%S)_all.png\""
            .. " && grim \"$f\" && wl-copy < \"$f\""
    ),
    { desc = "screenshot: all monitors" }
)

-- Picks a colour from anywhere on screen and puts the hex on the clipboard.
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -an"), { desc = "colour picker" })
