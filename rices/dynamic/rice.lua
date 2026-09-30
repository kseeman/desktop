return {
    description = "Colours taken from whatever wallpaper is up",

    -- Everything comes from the image, via matugen. There is no palette.lua
    -- beside this file, so nothing is pinned -- change the wallpaper and the
    -- whole desktop follows it.
    --
    -- A rice can do both: add a palette.lua naming one or two colours and those
    -- win, while the rest keep following the image.
    palette_from = "wallpaper",

    -- No wallpaper named on purpose. This rice has no look of its own to
    -- impose; it wears whatever is already up, which is what makes it the one
    -- to switch to when you want the desktop to follow a picture.

    look = {
        gaps_in = 3,
        gaps_out = 8,
        border_size = 2,
        rounding = 10,
        blur = true,
        motion_speed = 4.2,

        icon_theme = "Tela-circle-grey",
    },
}
