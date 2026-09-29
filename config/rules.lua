-- -----------------------------------------------------------------------------
-- Window and layer rules
-- -----------------------------------------------------------------------------
--
-- Ported from the tracked windowrules.conf, where the same directive was
-- repeated once per application: seventy-odd lines that differed only in a
-- class name. Here they are data, which is the first place this migration buys
-- something rather than merely moving it -- adding an application is a string
-- in a list, and the rule it gets is stated once.
--
-- Rules are kept for applications that are not installed. They cost nothing at
-- runtime, and dropping them would be a decision about which software to keep
-- rather than a faithful port.

-- -----------------------------------------------------------------------------
-- Transparency
-- -----------------------------------------------------------------------------

-- Opacity is one space-separated string of active, inactive and fullscreen --
-- not a list -- which the config gate caught rather than a login would have.
-- Fullscreen stays at 1 throughout: dimming a video because it lost focus to a
-- notification is never what is wanted.
--
-- Editors and file managers sit at one level, utility and tray windows a little
-- lower, and anything that plays video or games stays closer to opaque.
local OPACITY = {
    { 0.90, 0.90, {
        "firefox",
        "brave-browser",
        "com.github.rafostar.Clapper",
    } },

    { 0.80, 0.80, {
        "code-oss",
        "[Cc]ode",
        "code-url-handler",
        "code-insiders-url-handler",
        "org.kde.dolphin",
        "org.kde.ark",
        "nwg-look",
        "qt5ct",
        "qt6ct",
        "kvantummanager",
        "com.github.tchx84.Flatseal",
        "hu.kramo.Cartridges",
        "com.obsproject.Studio",
        "gnome-boxes",
        "vesktop",
        "discord",
        "WebCord",
        "ArmCord",
        "app.drey.Warp",
        "net.davidotek.pupgui2",
        "yad",
        "Signal",
        "io.github.alainm23.planify",
        "io.gitlab.theevilskeleton.Upscaler",
        "com.github.unrud.VideoDownloader",
        "io.gitlab.adhami3310.Impression",
        "io.missioncenter.MissionCenter",
        "io.github.flattool.Warehouse",
    } },

    { 0.80, 0.70, {
        "org.pulseaudio.pavucontrol",
        "blueman-manager",
        "nm-applet",
        "nm-connection-editor",
        "org.kde.polkit-kde-authentication-agent-1",
        "polkit-gnome-authentication-agent-1",
        "org.freedesktop.impl.portal.desktop.gtk",
        "org.freedesktop.impl.portal.desktop.hyprland",
    } },

    { 0.70, 0.70, {
        "[Ss]team",
        "steamwebhelper",
        "[Ss]potify",
    } },
}

for _, group in ipairs(OPACITY) do
    local active, inactive, classes = group[1], group[2], group[3]

    for _, class in ipairs(classes) do
        hl.window_rule({
            name = "opacity-" .. class,
            match = { class = "^(" .. class .. ")$" },
            opacity = string.format("%.2f %.2f 1", active, inactive),
        })
    end
end

-- Spotify announces itself by title before its class settles, so the free and
-- premium builds are matched that way rather than by class.
for _, title in ipairs({ "Spotify Free", "Spotify Premium" }) do
    hl.window_rule({
        name = "opacity-" .. title,
        match = { initial_title = "^(" .. title .. ")$" },
        opacity = "0.70 0.70 1",
    })
end

-- -----------------------------------------------------------------------------
-- Floating
-- -----------------------------------------------------------------------------

-- Dialog-shaped applications that tile badly: one window, fixed size, opened to
-- do one thing.
local FLOAT = {
    "Signal",
    "com.github.rafostar.Clapper",
    "app.drey.Warp",
    "net.davidotek.pupgui2",
    "yad",
    "eog",
    "io.github.alainm23.planify",
    "io.gitlab.theevilskeleton.Upscaler",
    "com.github.unrud.VideoDownloader",
    "io.gitlab.adhami3310.Impression",
    "io.missioncenter.MissionCenter",
    "org.kde.kcalc",
    "Emulator",
    "1password",
    "pol.exe",
}

for _, class in ipairs(FLOAT) do
    hl.window_rule({
        name = "float-" .. class,
        match = { class = "^(" .. class .. ")$" },
        float = true,
    })
end

-- -----------------------------------------------------------------------------
-- Idle inhibition
-- -----------------------------------------------------------------------------

-- Fullscreen video should not let the screen lock underneath it. Matched as one
-- alternation per group because that is how the source expressed it and the
-- groups are meaningfully different kinds of application.
local IDLE_INHIBIT = {
    "^(.*celluloid.*)$|^(.*mpv.*)$|^(.*vlc.*)$",
    "^(.*[Ss]potify.*)$",
    "^(.*LibreWolf.*)$|^(.*floorp.*)$|^(.*brave-browser.*)$|^(.*firefox.*)$"
        .. "|^(.*chromium.*)$|^(.*zen.*)$|^(.*vivaldi.*)$",
}

for index, pattern in ipairs(IDLE_INHIBIT) do
    hl.window_rule({
        name = "idle-inhibit-" .. index,
        match = { class = pattern },
        idle_inhibit = "fullscreen",
    })
end

-- -----------------------------------------------------------------------------
-- Individual rules
-- -----------------------------------------------------------------------------

-- Picture-in-picture: floated, pinned above everything, aspect locked, and
-- parked in the lower right. The position and size are fractions of the monitor
-- rather than pixels, so it lands in the same visual place on the 1440p
-- ultrawide and the 4K panel.
hl.window_rule({
    name = "picture-in-picture",
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    tag = "+picture-in-picture",
    float = true,
    keep_aspect_ratio = true,
    move = "(monitor_w*0.73) (monitor_h*0.72)",
    size = "(monitor_w*0.25) (monitor_h*0.25)",
    pin = true,
})

-- JetBrains IDEs open transient popups named win<n> that steal focus as they
-- appear, which makes typing land in the wrong place mid-completion.
hl.window_rule({
    name = "jetbrains-no-steal",
    match = { class = "^(.*jetbrains.*)$", title = "^(win[0-9]+)$" },
    no_focus = true,
})

-- Ignore maximize requests from applications. Hyprland's own example ships this
-- and it is the difference between a tiling layout and one that applications
-- rearrange.
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Empty class and title, floating, XWayland: a drag proxy rather than a window.
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- -----------------------------------------------------------------------------
-- Layer rules
-- -----------------------------------------------------------------------------

-- Blur behind the shell's own surfaces. The namespaces here are the ones in use
-- today, and a namespace that no longer exists is simply a rule that never
-- matches -- which is why the swaync and logout entries are left alone rather
-- than pruned as each is replaced.
for _, namespace in ipairs({
    "pill",
    "notifications",
    "swaync-notification-window",
    "swaync-control-center",
    "logout_dialog",
}) do
    hl.layer_rule({
        name = "blur-" .. namespace,
        match = { namespace = namespace },
        blur = true,
        ignore_alpha = 0,
    })
end
