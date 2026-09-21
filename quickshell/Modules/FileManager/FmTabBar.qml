import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// Compact browser-style tabs. Reordering is deliberately exposed as buttons
// as well as shortcuts: it stays usable with a pointer even when the strip is
// too crowded for reliable drag targets.
Rectangle {
    id: root

    property var tabs: []
    property int activeIndex: 0

    signal tabActivated(int index)
    signal tabClosed(int index)
    signal newTabRequested
    signal moveRequested(int from, int to)

    implicitHeight: 38
    color: Style.surfaceContainer

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Style.dividerWidth
        color: Style.outlineMedium
    }

    Row {
        id: tabActions

        anchors.right: parent.right
        anchors.rightMargin: Style.spacingS
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingXXS

        DankActionButton {
            enabled: root.activeIndex > 0
            iconName: "arrow_back"
            iconSize: Style.iconSizeSmall
            buttonSize: 28
            tooltipText: I18n.tr("Move tab left (Ctrl+Shift+Page Up)")
            onClicked: root.moveRequested(root.activeIndex, root.activeIndex - 1)
        }

        DankActionButton {
            enabled: root.activeIndex >= 0 && root.activeIndex < root.tabs.length - 1
            iconName: "arrow_forward"
            iconSize: Style.iconSizeSmall
            buttonSize: 28
            tooltipText: I18n.tr("Move tab right (Ctrl+Shift+Page Down)")
            onClicked: root.moveRequested(root.activeIndex, root.activeIndex + 1)
        }

        DankActionButton {
            iconName: "add"
            iconSize: Style.iconSizeSmall
            buttonSize: 28
            tooltipText: I18n.tr("New tab (Ctrl+T)")
            onClicked: root.newTabRequested()
        }
    }

    Flickable {
        anchors.left: parent.left
        anchors.right: tabActions.left
        anchors.rightMargin: Style.spacingS
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentWidth: tabRow.width
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Row {
            id: tabRow

            height: parent.height
            spacing: 0

            Repeater {
                model: root.tabs

                Rectangle {
                    id: tab

                    required property var modelData
                    required property int index

                    readonly property bool current: index === root.activeIndex

                    width: Math.max(112, Math.min(220, tabLabel.implicitWidth + closeButton.width + Style.spacingL * 2))
                    height: tabRow.height
                    color: current ? Style.surface : tabMouse.containsMouse ? Style.surfaceHover : "transparent"

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: tab.current
                        width: Math.max(Style.tabIndicatorMinWidth, parent.width - Style.spacingL * 2)
                        height: Style.tabIndicatorHeight
                        radius: height / 2
                        color: Style.primary
                    }

                    StyledText {
                        id: tabLabel

                        anchors.left: parent.left
                        anchors.leftMargin: Style.spacingM
                        anchors.right: closeButton.left
                        anchors.rightMargin: Style.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.title || I18n.tr("New tab")
                        color: tab.current ? Style.surfaceText : Style.surfaceTextMedium
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: tab.current ? Font.Medium : Font.Normal
                        wrapMode: Text.NoWrap
                        elide: Text.ElideMiddle
                    }

                    MouseArea {
                        id: tabMouse

                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton)
                                root.tabClosed(tab.index);
                            else
                                root.tabActivated(tab.index);
                        }
                    }

                    DankActionButton {
                        id: closeButton

                        anchors.right: parent.right
                        anchors.rightMargin: Style.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: root.tabs.length > 1
                        iconName: "close"
                        iconSize: 14
                        buttonSize: 26
                        tooltipText: enabled ? I18n.tr("Close tab (Ctrl+W)") : I18n.tr("At least one tab stays open")
                        onClicked: root.tabClosed(tab.index)
                    }
                }
            }
        }
    }
}
