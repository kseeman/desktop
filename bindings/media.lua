-- Audio, and the media keys.
--
-- hyde-shell volumecontrol was a script that changed the volume, read it back
-- and raised a notify-send OSD. Only the first of those needs a tool: Hyprland
-- draws notifications itself, so the OSD is a Lua call rather than a dependency
-- on a notification daemon being up.
--
-- The io.popen below is safe despite running a command. A Lua function handed
-- to hl.bind is stored, not called, so nothing here executes when the config is
-- read -- verified on 0.56.2 the same way hl.on was.
local SINK = "@DEFAULT_AUDIO_SINK@"
local SOURCE = "@DEFAULT_AUDIO_SOURCE@"

local STEP = "5%"

-- Locked so the keys keep working on the lock screen, and repeating so holding
-- one ramps rather than stepping once. Both carried over from the source, where
-- they are the `l` and `e` in binddl/binddel.
local HELD = { locked = true, repeating = true }
local TAP = { locked = true }

-- `wpctl get-volume` prints "Volume: 0.45", or "Volume: 0.45 [MUTED]".
local function read_volume(target)
    local pipe = io.popen("wpctl get-volume " .. target .. " 2>/dev/null")
    if not pipe then
        return nil, false
    end

    local out = pipe:read("*a") or ""
    pipe:close()

    local value = tonumber(out:match("Volume:%s*([%d.]+)"))
    return value, out:find("MUTED") ~= nil
end

-- One notification handle, reused. Creating a fresh one per keypress would
-- stack a column of them while the volume ramps; replacing the text of a live
-- one is what makes it read as a single OSD.
local osd

local function show(text)
    if osd and osd:is_alive() then
        osd:set_text(text)
        osd:set_timeout(1500)
    else
        osd = hl.notification.create({ text = text, timeout = 1500 })
    end
end

local function report(label, target)
    local value, muted = read_volume(target)

    if not value then
        show(label .. ": unavailable")
    elseif muted then
        show(label .. ": muted")
    else
        show(string.format("%s: %d%%", label, math.floor(value * 100 + 0.5)))
    end
end

local function output(command)
    return function()
        os.execute("wpctl " .. command)
        report("volume", SINK)
    end
end

-- -l 1 caps the volume at 100%. Without it wpctl happily goes past unity and
-- into distortion, which is a surprising thing for a volume key to do.
hl.bind("XF86AudioRaiseVolume", output("set-volume -l 1 " .. SINK .. " " .. STEP .. "+"), HELD)
hl.bind("XF86AudioLowerVolume", output("set-volume " .. SINK .. " " .. STEP .. "-"), HELD)
hl.bind("XF86AudioMute", output("set-mute " .. SINK .. " toggle"), TAP)

-- F10/F11/F12 duplicate the media keys for keyboards without them.
hl.bind("F12", output("set-volume -l 1 " .. SINK .. " " .. STEP .. "+"), HELD)
hl.bind("F11", output("set-volume " .. SINK .. " " .. STEP .. "-"), HELD)
hl.bind("F10", output("set-mute " .. SINK .. " toggle"), TAP)

hl.bind("XF86AudioMicMute", function()
    os.execute("wpctl set-mute " .. SOURCE .. " toggle")
    report("microphone", SOURCE)
end, TAP)

-- Playback. playerctl talks MPRIS, so these reach whatever is playing without
-- knowing which application it is.
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), TAP)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), TAP)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), TAP)
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), TAP)

-- Brightness keys are deliberately unbound. brightnessctl finds no backlight on
-- this machine -- the only device it reports is a scroll-lock LED -- so binding
-- XF86MonBrightness* to it would dim a keyboard light rather than a screen.
-- External monitors need DDC/CI (ddcutil), which is a separate decision.
