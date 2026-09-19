import QtQuick
import Quickshell
import qs.DankCommon.Common
import qs.DankCommon.Widgets

FloatingWindow {
    id: settingsWindow

    function show() {
        visible = true;
    }

    function hide() {
        visible = false;
    }

    title: I18n.tr("File Manager Settings")
    minimumSize: Qt.size(520, 420)
    implicitWidth: 880
    implicitHeight: 720
    color: Style.surface
    visible: false

    onClosed: hide()

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                settingsWindow.hide();
                event.accepted = true;
            }
        }

        Column {
            anchors.fill: parent
            spacing: 0

            DankWindowHeader {
                id: header

                width: parent.width
                z: 10
                controls: windowControls
                title: I18n.tr("Settings")
                onCloseRequested: settingsWindow.hide()
            }

            Item {
                width: parent.width
                height: parent.height - header.height
                clip: true

                Rectangle {
                    id: sidebar

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 220
                    color: "transparent"

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Style.dividerWidth
                        color: Style.outlineVariant
                    }

                    Column {
                        anchors.fill: parent
                        anchors.rightMargin: Style.dividerWidth
                        anchors.margins: Style.spacingL
                        spacing: Style.spacingXS

                        Rectangle {
                            width: parent.width
                            height: 56
                            radius: Style.cornerRadius
                            color: Style.primaryHover

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Style.spacingM
                                spacing: Style.spacingM

                                DankIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "info"
                                    size: Style.iconSize
                                    color: Style.primary
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    StyledText {
                                        text: I18n.tr("About")
                                        font.pixelSize: Style.fontSizeMedium
                                        font.weight: Font.Medium
                                        color: Style.surfaceText
                                        wrapMode: Text.NoWrap
                                    }

                                    StyledText {
                                        text: I18n.tr("Version and links")
                                        font.pixelSize: Style.fontSizeSmall
                                        color: Style.surfaceVariantText
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }
                        }
                    }
                }

                FmAboutPage {
                    anchors.left: sidebar.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                }
            }
        }
    }

    FloatingWindowControls {
        id: windowControls

        targetWindow: settingsWindow
    }
}
