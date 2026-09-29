pragma Singleton

import QtQuick

// The bar's colour block.
//
// Every consumer in this desktop keeps its colours in one place and nowhere
// else: lib/palette.lua for the compositor, a `*` block in rofi, @define-color
// in wlogout, a $variable block in hyprlock. QML gets a singleton, which is the
// same idea with the language's own mechanism.
//
// Values mirror lib/palette.lua. P6 generates this file; until then it is the
// only thing to edit when the scheme changes.
QtObject {
    readonly property color root: "#120D1D"
    readonly property color base: "#1F1829"
    readonly property color raised: "#322948"
    readonly property color overlay: "#453852"
    readonly property color muted: "#595162"

    readonly property color accent: "#6E5E8C"
    readonly property color accentDeep: "#594583"

    readonly property color bar: "#18151A"

    readonly property color fg: "#B5B0B1"
    readonly property color fgDim: "#8F7D86"

    // One motion language, the same constants config/animations.lua uses. The
    // compositor animates windows at 420ms on cubic-bezier(0.16, 1, 0.3, 1);
    // anything here that moves has to agree, or the desktop reads as two
    // programs sharing a screen.
    readonly property int motionDuration: 420
    readonly property var motionEasing: [0.16, 1.0, 0.30, 1.0, 1, 1]

    readonly property string fontFamily: "CaskaydiaCove Nerd Font"
}
