// One rounded group on the bar.
//
// The reference bar is not a continuous strip: it is discrete pills with space
// between them, and the grouping is what carries the design. Everything that
// goes on the bar goes inside one of these.

import QtQuick

Rectangle {
    default property alias content: inner.data

    implicitWidth: inner.childrenRect.width + 24
    implicitHeight: 24

    radius: 12
    color: Theme.base

    Item {
        id: inner
        anchors.fill: parent
    }
}
