import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// Application chooser for the selected file.
DankDialog {
    id: root

    required property var service
    property string fileName: ""

    signal chosen(string appId, bool makeDefault)
    signal customRequested

    readonly property int rowHeight: 44

    function show(name) {
        fileName = name;
        alwaysToggle.checked = false;
        opened = true;
    }

    embedded: false
    opened: false
    title: I18n.tr("Open with")
    iconName: "open_in_new"
    supportingText: fileName + (service.mimeType ? " · " + service.mimeType : "")
    maximumWidth: 460
    acceptEnabled: false

    onRejected: opened = false

    StyledText {
        width: parent.width
        visible: root.service.apps.length === 0
        text: root.service.loading ? I18n.tr("Looking for applications…") : I18n.tr("No application is registered for this file type")
        font.pixelSize: Style.fontSizeSmall
        color: Style.surfaceTextSecondary
        wrapMode: Text.WordWrap
    }

    DankListView {
        width: parent.width
        height: Math.min(360, root.service.apps.length * root.rowHeight)
        model: root.service.apps
        clip: true

        delegate: Rectangle {
            id: appRow

            required property var modelData

            readonly property bool isDefault: modelData.id === root.service.defaultId

            width: ListView.view.width
            height: root.rowHeight
            radius: Style.cornerRadius
            color: rowHover.containsMouse ? Style.widgetBaseHoverColor : "transparent"

            Row {
                anchors.fill: parent
                anchors.leftMargin: Style.spacingS
                anchors.rightMargin: Style.spacingS
                spacing: Style.spacingM

                Item {
                    width: 28
                    height: 28
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: appIcon

                        anchors.fill: parent
                        source: root.service.iconSource(appRow.modelData.icon)
                        sourceSize.width: 28
                        sourceSize.height: 28
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        visible: !appIcon.visible
                        name: "apps"
                        size: Style.iconSize
                        color: Style.surfaceTextSecondary
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 28 - Style.spacingM * 2 - (appRow.isDefault ? defaultTag.width : 0)
                    text: appRow.modelData.name
                    font.pixelSize: Style.fontSizeSmall
                    color: Style.surfaceText
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                StyledText {
                    id: defaultTag

                    anchors.verticalCenter: parent.verticalCenter
                    visible: appRow.isDefault
                    text: I18n.tr("default")
                    font.family: Fonts.mono
                    font.pixelSize: Style.fontSizeSmall - 1
                    color: Style.primary
                    wrapMode: Text.NoWrap
                }
            }

            MouseArea {
                id: rowHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.opened = false;
                    root.chosen(appRow.modelData.id, alwaysToggle.checked);
                }
            }
        }
    }

    Rectangle {
        width: parent.width
        height: root.rowHeight
        radius: Style.cornerRadius
        color: customHover.containsMouse ? Style.widgetBaseHoverColor : "transparent"

        Row {
            anchors.fill: parent
            anchors.leftMargin: Style.spacingS
            spacing: Style.spacingM

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                name: "terminal"
                size: Style.iconSize
                color: Style.surfaceTextSecondary
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Other application…")
                font.pixelSize: Style.fontSizeSmall
                color: Style.surfaceText
                wrapMode: Text.NoWrap
            }
        }

        MouseArea {
            id: customHover

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.opened = false;
                root.customRequested();
            }
        }
    }

    Rectangle {
        width: parent.width
        height: Style.dividerWidth
        color: Style.outlineMedium
    }

    DankToggle {
        id: alwaysToggle

        width: parent.width
        // A custom command has no desktop id, so it cannot become the default;
        // the toggle only applies to the list above.
        text: I18n.tr("Always use for this file type")
        description: root.service.mimeType
    }

    actions: [
        DankButton {
            text: I18n.tr("Cancel")
            maximumWidth: root.actionWidth
            backgroundColor: Style.surfaceContainerHighest
            textColor: Style.surfaceText
            onClicked: root.rejected()
        }
    ]
}
