import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// One clickable column header. Click to sort by this field, click again to
// reverse.
Item {
    id: root

    required property var owner
    required property string field
    property string text: ""
    property int alignment: Text.AlignLeft

    readonly property bool active: owner.sortBy === field

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.alignment === Text.AlignLeft ? parent.left : undefined
        anchors.right: root.alignment === Text.AlignRight ? parent.right : undefined
        spacing: Style.spacingXXS

        StyledText {
            // Fixed-height rows: StyledText defaults to WordWrap, which overflows
            // them and overlaps the row below.
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.pixelSize: Style.fontSizeSmall
            font.weight: root.active ? Font.Medium : Font.Normal
            color: root.active ? Style.primary : headerHover.containsMouse ? Style.surfaceText : Style.surfaceTextMedium
        }

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.active
            name: root.owner.sortAscending ? "arrow_upward" : "arrow_downward"
            size: Style.iconSizeSmall - 4
            color: Style.primary
        }
    }

    MouseArea {
        id: headerHover

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.owner.sortByField(root.field);
            root.owner.takeFocus();
        }
    }
}
