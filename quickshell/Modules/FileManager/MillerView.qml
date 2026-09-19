import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// Horizontal strip of columns. Presentation only - all selection state lives in
// the owning FileManagerContent.
Item {
    id: root

    required property var owner

    // Columns tile the strip exactly - three when there is room, fewer when the
    // window is narrow. Deriving the width from a count that fits keeps a
    // half-column from hanging off the left edge once the chain scrolls.
    readonly property int minColumnWidth: 190
    readonly property int visibleColumns: Math.max(1, Math.min(3, Math.floor(width / minColumnWidth)))
    readonly property int columnWidth: Math.max(minColumnWidth, Math.floor(width / visibleColumns))

    clip: true

    ListView {
        id: columnsView

        anchors.fill: parent
        orientation: ListView.Horizontal
        model: root.owner.columns
        cacheBuffer: root.columnWidth * 4
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.owner.activeColumn
        highlightMoveDuration: Style.shortDuration
        preferredHighlightBegin: 0
        preferredHighlightEnd: width

        // Track the deepest column rather than the focused one: the child
        // preview is the thing the user just revealed.
        readonly property int trailingIndex: Math.max(0, root.owner.columns.length - 1)

        // Columns arrive asynchronously and the strip is laid out after them, so
        // scrolling has to be re-driven from every input that can change it -
        // positioning against a zero width or a missing delegate is a no-op.
        function scrollToTrailing() {
            if (width <= 0 || count === 0)
                return;
            // Delegates are resized lazily after the strip changes width, and
            // positioning against stale geometry leaves a half column at the
            // left edge - lay out first.
            forceLayout();
            positionViewAtIndex(Math.min(trailingIndex, count - 1), ListView.End);
        }

        onTrailingIndexChanged: Qt.callLater(scrollToTrailing)
        onCountChanged: Qt.callLater(scrollToTrailing)
        onWidthChanged: Qt.callLater(scrollToTrailing)
        onCurrentIndexChanged: Qt.callLater(() => positionViewAtIndex(currentIndex, ListView.Contain))
        Component.onCompleted: Qt.callLater(scrollToTrailing)

        delegate: MillerColumn {
            required property int index
            required property string modelData

            width: root.columnWidth
            height: columnsView.height
            owner: root.owner
            column: index
            path: modelData
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.dividerWidth
        color: Style.outlineMedium
    }
}
