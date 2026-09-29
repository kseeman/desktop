// The bar.
//
// A Quickshell shell rather than a waybar config, because the reference this is
// built toward -- github.com/Gakuseei/Ricelin -- puts a media popup with album
// art and a draggable scrubber in the bar, and that is not something waybar can
// be configured into.
//
// Run it with:
//
//   quickshell -p <this directory>
//
// or, from a window that is not this session:
//
//   os/linux/desktop/nested.sh --exec "quickshell -p <this directory>"
//
// This is the skeleton: one panel per monitor, the clock, and the pill shape
// everything else hangs off. Modules arrive after it is confirmed to draw.

import QtQuick
import QtQuick.Layouts
import Quickshell

ShellRoot {
    // One bar per monitor. Variants is Quickshell's way of saying "one of these
    // for each of those" -- without it the bar appears on whichever screen
    // Wayland happened to hand over, which on a two-monitor setup is a coin
    // toss rather than a choice.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            screen: modelData

            // Layer-shell anchors. Anchoring left and right as well as top is
            // what makes the panel span the monitor rather than shrink to its
            // contents.
            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34

            // The strip itself is near-black and the pills sit on it. Keeping
            // the panel transparent and colouring the pills is what produces
            // the floating-groups look rather than one continuous bar.
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Theme.bar
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                // Left, centre and right are separate groups with space pushed
                // between them, which is what keeps the clock centred rather
                // than merely somewhere in the middle.
                RowLayout {
                    id: left
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Pill {
                    Text {
                        anchors.centerIn: parent
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 13

                        // Updated by the timer below rather than by a binding on
                        // a clock property: a binding would re-evaluate on every
                        // frame that touches it, and this needs to change once a
                        // second.
                        id: clockText
                        text: Qt.formatDateTime(new Date(), "HH:mm")
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    id: right
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
