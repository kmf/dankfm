import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Rectangle {
    id: root

    property var crumbs: []
    property string trailingCrumb: ""
    property string viewMode: "columns"
    property bool canGoUp: true
    property bool bookmarked: false
    property bool sidebarShown: true
    property bool previewShown: true
    property string editablePath: ""
    property bool pathEditMode: false

    signal crumbActivated(string path)
    signal upRequested
    signal viewModeRequested(string mode)
    signal bookmarkToggled
    signal terminalRequested
    signal sidebarToggled
    signal previewToggled
    signal pathSubmitted(string path)
    signal pathEditFinished
    signal settingsRequested

    // Reveals the path as text. The crumbs are buttons, so a double click is the
    // only press on them that is not already spoken for; Ctrl+L gets here too.
    function beginPathEdit() {
        pathEditMode = true;
        pathField.text = root.editablePath;
        Qt.callLater(() => {
            pathField.forceActiveFocus();
            pathField.selectAll();
        });
    }

    function endPathEdit() {
        // Clearing the field's focus explicitly matters: hiding an item that
        // holds focus leaves the focus scope pointing at something invisible,
        // and every keybinding stops working until the user clicks a row.
        pathField.focus = false;
        pathEditMode = false;
        pathEditFinished();
    }

    implicitHeight: 44
    color: Style.surfaceContainer

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Style.dividerWidth
        color: Style.outlineMedium
    }

    Row {
        id: leadingControls

        anchors.left: parent.left
        anchors.leftMargin: Style.spacingS
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingXXS

        DankActionButton {
            iconName: root.sidebarShown ? "left_panel_close" : "left_panel_open"
            tooltipText: root.sidebarShown ? I18n.tr("Hide places") : I18n.tr("Show places")
            onClicked: root.sidebarToggled()
        }

        DankActionButton {
            iconName: "arrow_upward"
            enabled: root.canGoUp
            onClicked: root.upRequested()
        }

        DankActionButton {
            iconName: "terminal"
            tooltipText: I18n.tr("Open terminal here")
            onClicked: root.terminalRequested()
        }

        DankActionButton {
            iconName: root.bookmarked ? "bookmark" : "bookmark_add"
            iconColor: root.bookmarked ? Style.primary : Style.onSurfaceVariant
            tooltipText: root.bookmarked ? I18n.tr("Remove bookmark") : I18n.tr("Bookmark this folder")
            onClicked: root.bookmarkToggled()
        }
    }

    // Blank strip beside the crumbs: a deep path leaves none, which is why the
    // crumbs themselves take a double click too.
    MouseArea {
        anchors.fill: crumbStrip
        visible: !root.pathEditMode
        onDoubleClicked: root.beginPathEdit()
    }

    DankTextField {
        id: pathField

        anchors.fill: crumbStrip
        visible: root.pathEditMode
        outlined: true
        topPadding: Style.spacingXXS
        bottomPadding: Style.spacingXXS
        font.family: Fonts.mono
        font.pixelSize: Style.fontSizeSmall

        onAccepted: {
            const path = text.trim();
            root.endPathEdit();
            if (path.length > 0)
                root.pathSubmitted(path);
        }
        Keys.onEscapePressed: root.endPathEdit()
        onActiveFocusChanged: {
            if (!activeFocus && root.pathEditMode)
                root.endPathEdit();
        }
    }

    Flickable {
        id: crumbStrip

        anchors.left: leadingControls.right
        anchors.leftMargin: Style.spacingS
        anchors.right: trailingControls.left
        anchors.rightMargin: Style.spacingS
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        visible: !root.pathEditMode
        contentWidth: crumbRow.width
        flickableDirection: Flickable.HorizontalFlick
        clip: true

        Row {
            id: crumbRow

            height: parent.height
            spacing: 0

            Repeater {
                model: root.crumbs

                Row {
                    required property var modelData
                    required property int index

                    height: crumbRow.height
                    spacing: 0

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: parent.index > 0
                        name: "chevron_right"
                        size: Style.iconSizeSmall - 2
                        color: Style.surfaceTextSecondary
                    }

                    Rectangle {
                        width: crumbLabel.implicitWidth + Style.spacingS * 2
                        height: crumbLabel.implicitHeight + Style.spacingXXS * 2
                        anchors.verticalCenter: parent.verticalCenter
                        radius: Style.cornerRadius
                        color: crumbHover.containsMouse ? Style.surfaceHover : "transparent"

                        StyledText {
                            // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                            // them and overlaps the row below.
                            wrapMode: Text.NoWrap
                            id: crumbLabel

                            anchors.centerIn: parent
                            text: parent.parent.modelData.label
                            font.family: Fonts.mono
                            font.pixelSize: Style.fontSizeSmall
                            color: Style.surfaceText
                        }

                        MouseArea {
                            id: crumbHover

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.crumbActivated(parent.parent.modelData.path)
                            onDoubleClicked: root.beginPathEdit()
                        }
                    }
                }
            }

            Row {
                height: crumbRow.height
                visible: root.trailingCrumb.length > 0
                spacing: 0

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "chevron_right"
                    size: Style.iconSizeSmall - 2
                    color: Style.surfaceTextSecondary
                }

                StyledText {
                    // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                    // them and overlaps the row below.
                    wrapMode: Text.NoWrap
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: Style.spacingS
                    text: root.trailingCrumb
                    font.family: Fonts.mono
                    font.pixelSize: Style.fontSizeSmall
                    color: Style.primary
                }
            }
        }
    }

    Row {
        id: trailingControls

        anchors.right: parent.right
        anchors.rightMargin: Style.spacingS
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingXXS

        Repeater {
            model: [
                {
                    "mode": "columns",
                    "icon": "view_column"
                },
                {
                    "mode": "list",
                    "icon": "list"
                },
                {
                    "mode": "grid",
                    "icon": "grid_view"
                }
            ]

            Rectangle {
                required property var modelData

                readonly property bool current: root.viewMode === modelData.mode

                width: 30
                height: 30
                radius: Style.cornerRadius
                color: current ? Style.primaryHover : modeHover.containsMouse ? Style.surfaceHover : "transparent"

                DankIcon {
                    anchors.centerIn: parent
                    name: parent.modelData.icon
                    size: Style.iconSizeSmall
                    color: parent.current ? Style.primary : Style.surfaceTextMedium
                }

                MouseArea {
                    id: modeHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.viewModeRequested(parent.modelData.mode)
                }
            }
        }

        DankActionButton {
            anchors.verticalCenter: parent.verticalCenter
            iconName: root.previewShown ? "right_panel_close" : "right_panel_open"
            tooltipText: root.previewShown ? I18n.tr("Hide preview") : I18n.tr("Show preview")
            onClicked: root.previewToggled()
        }

        DankActionButton {
            anchors.verticalCenter: parent.verticalCenter
            iconName: "settings"
            tooltipText: I18n.tr("Settings")
            onClicked: root.settingsRequested()
        }
    }
}
