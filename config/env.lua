-- Environment variables for the graphical session.
--
-- Owned here rather than inherited. This session starts through uwsm, which
-- also sources ~/.config/uwsm/env-hyprland.d/00-hyde.sh -- so until HyDE is
-- removed, the Qt, Firefox and Electron variables below are being set twice,
-- once by HyDE and once here. That is deliberate: the duplicate is harmless
-- (same values), and without it this session would quietly depend on a file
-- HyDE owns and would lose those settings the moment HyDE is uninstalled.
--
-- Hardware-specific variables do NOT belong here. NVIDIA driver selection,
-- VA-API backends and anything else describing one machine go in
-- ~/.userconfig/hypr/local.lua, for the same reason monitors.conf and
-- nvidia.conf are excluded from this repo.

-- Qt applications. QT_QPA_PLATFORMTHEME points at qt6ct, which is what makes
-- Kvantum and the qt5ct/qt6ct colour files apply.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- GTK and friends.
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_SCALE", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Cursor size only. The cursor *theme* is part of the look and is set with the
-- rest of the palette, not here, so that changing themes does not mean editing
-- an environment file.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
