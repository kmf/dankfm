import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Rectangle {
    id: root

    property string pathLabel: ""
    property int itemCount: 0
    property string selectionLabel: ""
    property bool hiddenFiles: false
    // Transient feedback from a file operation; takes over the item count while
    // it is showing, since that is the line the user is not reading anyway.
    property string message: ""

    signal toggleHidden

    implicitHeight: 28
    color: Style.surfaceContainer

    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: Style.dividerWidth
        color: Style.outlineMedium
    }

    StyledText {
        // Fixed-height rows: StyledText defaults to WordWrap, which overflows
        // them and overlaps the row below.
        wrapMode: Text.NoWrap
        anchors.left: parent.left
        anchors.leftMargin: Style.spacingM
        anchors.right: trailing.left
        anchors.rightMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideMiddle
        text: root.pathLabel
        font.family: Fonts.mono
        font.pixelSize: Style.fontSizeSmall - 1
        color: Style.surfaceTextMedium
    }

    Row {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingM

        StyledText {
            // Fixed-height rows: StyledText defaults to WordWrap, which overflows
            // them and overlaps the row below.
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
            text: root.message ? root.message : root.itemCount + " " + I18n.tr("items") + (root.selectionLabel ? " · " + root.selectionLabel : "")
            color: root.message ? Style.primary : Style.surfaceTextMedium
            font.family: Fonts.mono
            font.pixelSize: Style.fontSizeSmall - 1
        }

        StyledText {
            // Fixed-height rows: StyledText defaults to WordWrap, which overflows
            // them and overlaps the row below.
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Hidden files") + ": " + (root.hiddenFiles ? I18n.tr("on") : I18n.tr("off"))
            font.family: Fonts.mono
            font.pixelSize: Style.fontSizeSmall - 1
            color: hiddenHover.containsMouse ? Style.primary : Style.surfaceTextSecondary

            MouseArea {
                id: hiddenHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleHidden()
            }
        }
    }
}
