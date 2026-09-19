import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import qs.Services

Item {
    id: aboutPage

    readonly property string githubUrl: "https://github.com/kmf/dankfm"
    readonly property string docsUrl: "https://danklinux.com/docs"
    readonly property string discordUrl: "https://discord.gg/ppWTpKmPgT"
    readonly property string kofiUrl: "https://ko-fi.com/danklinux"
    readonly property string licenseUrl: githubUrl + "/blob/main/LICENSE"

    readonly property string versionText: {
        const version = DankFmService.appVersion;
        if (!version || version === "dev")
            return "dankfm (dev)";
        if (/^[\d.]+$/.test(version))
            return "dankfm v" + version;
        return "dankfm " + version;
    }

    DankFlickable {
        anchors.fill: parent
        clip: true
        contentHeight: mainColumn.height + Style.spacingXL
        contentWidth: width

        Column {
            id: mainColumn

            topPadding: Style.spacingL
            width: Math.min(550, parent.width - Style.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.spacingXL

            StyledRect {
                width: parent.width
                height: headerSection.implicitHeight + Style.spacingL * 2
                radius: Style.cornerRadiusL
                color: Style.surfaceContainerHigh

                Column {
                    id: headerSection

                    anchors.fill: parent
                    anchors.margins: Style.spacingL
                    spacing: Style.spacingM

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Style.spacingL

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "folder_open"
                            size: 72
                            color: Style.primary
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "DANK FM"
                            font.pixelSize: 38
                            font.weight: Style.fontWeightBold
                            color: Style.surfaceText
                            wrapMode: Text.NoWrap
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: aboutPage.versionText
                        font.pixelSize: Style.fontSizeXLarge
                        font.weight: Style.fontWeightBold
                        color: Style.surfaceText
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.NoWrap
                    }

                    StyledText {
                        width: parent.width
                        text: I18n.tr("A miller-column file manager.")
                        font.pixelSize: Style.fontSizeMedium
                        font.italic: true
                        color: Style.surfaceVariantText
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        id: resourceButtonsRow

                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Style.spacingS

                        property bool compactMode: aboutPage.width < 450

                        DankButton {
                            id: docsButton

                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("Docs")
                            iconName: "menu_book"
                            iconSize: Style.chipIconSize
                            backgroundColor: Style.secondaryContainer
                            textColor: Style.onSecondaryContainer
                            onClicked: Qt.openUrlExternally(aboutPage.docsUrl)
                        }

                        DankButton {
                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("GitHub")
                            iconName: "code"
                            iconSize: Style.chipIconSize
                            backgroundColor: Style.secondaryContainer
                            textColor: Style.onSecondaryContainer
                            onClicked: Qt.openUrlExternally(aboutPage.githubUrl)
                        }

                        DankButton {
                            text: resourceButtonsRow.compactMode ? "" : I18n.tr("Ko-fi")
                            iconName: "favorite"
                            iconSize: Style.chipIconSize
                            backgroundColor: Style.secondaryContainer
                            textColor: Style.onSecondaryContainer
                            onClicked: Qt.openUrlExternally(aboutPage.kofiUrl)
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: projectSection.implicitHeight + Style.spacingL * 2
                radius: Style.cornerRadiusL
                color: Style.surfaceContainerHigh

                Column {
                    id: projectSection

                    anchors.fill: parent
                    anchors.margins: Style.spacingL
                    spacing: Style.spacingM

                    Row {
                        width: parent.width
                        spacing: Style.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "info"
                            size: Style.iconSize
                            color: Style.primary
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("About")
                            font.pixelSize: Style.fontSizeLarge
                            font.weight: Font.Medium
                            color: Style.surfaceText
                            wrapMode: Text.NoWrap
                        }
                    }

                    StyledText {
                        width: parent.width
                        text: I18n.tr('DankFM is a miller-column file manager for the modern Linux desktop with a <a href="https://m3.material.io/" style="text-decoration:none; color:%1;">material 3 inspired</a> design, plus a CLI and socket API for integrations.<br /><br/>It is built with <a href="https://quickshell.org" style="text-decoration:none; color:%1;">Quickshell</a>, a Qt 6 framework for building desktop shells, and <a href="https://go.dev" style="text-decoration:none; color:%1;">Go</a>, a statically typed, compiled programming language.').arg(Style.primary)
                        textFormat: Text.RichText
                        font.pixelSize: Style.fontSizeMedium
                        linkColor: Style.primary
                        color: Style.surfaceVariantText
                        wrapMode: Text.WordWrap
                        onLinkActivated: url => Qt.openUrlExternally(url)

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            acceptedButtons: Qt.NoButton
                            propagateComposedEvents: true
                        }
                    }
                }
            }

            StyledRect {
                width: parent.width
                height: backendSection.implicitHeight + Style.spacingL * 2
                radius: Style.cornerRadiusL
                color: Style.surfaceContainerHigh

                Column {
                    id: backendSection

                    anchors.fill: parent
                    anchors.margins: Style.spacingL
                    spacing: Style.spacingM

                    Row {
                        width: parent.width
                        spacing: Style.spacingM

                        DankIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "dns"
                            size: Style.iconSize
                            color: Style.primary
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("Backend")
                            font.pixelSize: Style.fontSizeLarge
                            font.weight: Font.Medium
                            color: Style.surfaceText
                            wrapMode: Text.NoWrap
                        }
                    }

                    Row {
                        spacing: Style.spacingL

                        Column {
                            spacing: 2

                            StyledText {
                                text: I18n.tr("Version")
                                font.pixelSize: Style.fontSizeSmall
                                color: Style.surfaceVariantText
                                wrapMode: Text.NoWrap
                            }

                            StyledText {
                                text: DankFmService.appVersion || "—"
                                font.pixelSize: Style.fontSizeMedium
                                font.weight: Font.Medium
                                color: Style.surfaceText
                                wrapMode: Text.NoWrap
                            }
                        }

                        Rectangle {
                            width: 1
                            height: Style.iconSizeLarge
                            color: Style.outlineVariant
                        }

                        Column {
                            spacing: 2

                            StyledText {
                                text: I18n.tr("API")
                                font.pixelSize: Style.fontSizeSmall
                                color: Style.surfaceVariantText
                                wrapMode: Text.NoWrap
                            }

                            StyledText {
                                text: DankFmService.apiVersion > 0 ? "v" + DankFmService.apiVersion : "—"
                                font.pixelSize: Style.fontSizeMedium
                                font.weight: Font.Medium
                                color: Style.surfaceText
                                wrapMode: Text.NoWrap
                            }
                        }

                        Rectangle {
                            width: 1
                            height: Style.iconSizeLarge
                            color: Style.outlineVariant
                        }

                        Column {
                            spacing: 2

                            StyledText {
                                text: I18n.tr("Status")
                                font.pixelSize: Style.fontSizeSmall
                                color: Style.surfaceVariantText
                                wrapMode: Text.NoWrap
                            }

                            Row {
                                spacing: 4

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Style.spacingS
                                    height: Style.spacingS
                                    radius: width / 2
                                    color: DankFmService.connected ? "#4ade80" : Style.error
                                }

                                StyledText {
                                    text: DankFmService.connected ? I18n.tr("Connected") : I18n.tr("Offline")
                                    font.pixelSize: Style.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Style.surfaceText
                                    wrapMode: Text.NoWrap
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Style.spacingS
                        visible: DankFmService.capabilities.length > 0

                        StyledText {
                            width: parent.width
                            text: I18n.tr("Capabilities")
                            font.pixelSize: Style.fontSizeSmall
                            color: Style.surfaceVariantText
                            wrapMode: Text.NoWrap
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: DankFmService.capabilities

                                Rectangle {
                                    required property var modelData

                                    width: capText.implicitWidth + Style.spacingL
                                    height: Style.fontSizeMedium + Style.spacingM
                                    radius: height / 2
                                    color: Style.withAlpha(Style.primary, Style.tonalTintAlpha)

                                    StyledText {
                                        id: capText

                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        font.pixelSize: Style.fontSizeSmall
                                        color: Style.primary
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.tr('<a href="%2" style="text-decoration:none; color:%1;">MIT License</a>').arg(Style.surfaceVariantText).arg(aboutPage.licenseUrl)
                font.pixelSize: Style.fontSizeMedium
                color: Style.surfaceVariantText
                textFormat: Text.RichText
                wrapMode: Text.NoWrap
                onLinkActivated: url => Qt.openUrlExternally(url)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                }
            }
        }
    }
}
