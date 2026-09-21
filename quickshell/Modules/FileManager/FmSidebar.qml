import QtCore
import QtQuick
import QtQuick.Controls
import qs.DankCommon.Common
import qs.DankCommon.Widgets

Rectangle {
    id: root

    property string currentPath: ""
    property var bookmarks: []
    property string trashPath: ""

    signal locationSelected(string path)
    signal bookmarkRemoved(string path)
    signal emptyTrashRequested

    function openTrashMenu(parentItem, localX, localY) {
        const point = parentItem.mapToItem(root, localX, localY);
        trashMenu.x = Math.max(0, Math.min(root.width - trashMenu.width, point.x));
        trashMenu.y = Math.max(0, Math.min(root.height - trashMenu.height, point.y));
        trashMenu.open();
    }

    function localPath(location) {
        return StandardPaths.writableLocation(location).toString().replace("file://", "");
    }

    function baseName(path) {
        return path === "/" ? "/" : path.split("/").filter(s => s.length > 0).pop() ?? path;
    }

    // TODO(prototype): REPOSITORIES should come from a git-repo scan and DEVICES
    // from udisks/lsblk. Both are placeholders in the design canvas too.
    readonly property var sections: [
        {
            "title": I18n.tr("Places"),
            "items": [
                {
                    "icon": "home",
                    "name": I18n.tr("Home"),
                    "path": localPath(StandardPaths.HomeLocation)
                },
                {
                    "icon": "download",
                    "name": I18n.tr("Downloads"),
                    "path": localPath(StandardPaths.DownloadLocation)
                },
                {
                    "icon": "description",
                    "name": I18n.tr("Documents"),
                    "path": localPath(StandardPaths.DocumentsLocation)
                },
                {
                    "icon": "image",
                    "name": I18n.tr("Pictures"),
                    "path": localPath(StandardPaths.PicturesLocation)
                },
                {
                    "icon": "movie",
                    "name": I18n.tr("Videos"),
                    "path": localPath(StandardPaths.MoviesLocation)
                },
                {
                    "icon": "music_note",
                    "name": I18n.tr("Music"),
                    "path": localPath(StandardPaths.MusicLocation)
                },
                {
                    "icon": "delete",
                    "name": I18n.tr("Trash"),
                    "path": root.trashPath
                }
            ]
        },
        {
            "title": I18n.tr("Bookmarks"),
            "removable": true,
            "items": root.bookmarks.map(path => ({
                        "icon": "bookmark",
                        "name": root.baseName(path),
                        "path": path
                    }))
        }
    ]

    color: Style.nestedSurface
    clip: true

    Column {
        anchors.fill: parent
        anchors.margins: Style.spacingS
        spacing: Style.spacingM

        Repeater {
            model: root.sections

            Column {
                id: sectionColumn

                required property var modelData

                width: parent.width
                spacing: Style.spacingXS
                visible: modelData.items.length > 0

                StyledText {
                    // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                    // them and overlaps the row below.
                    wrapMode: Text.NoWrap
                    text: parent.modelData.title.toUpperCase()
                    font.family: Fonts.mono
                    font.pixelSize: Style.fontSizeSmall - 1
                    font.letterSpacing: 0.6
                    color: Style.surfaceTextSecondary
                    leftPadding: Style.spacingS
                    bottomPadding: Style.spacingXXS
                }

                Repeater {
                    model: parent.modelData.items

                    Rectangle {
                        required property var modelData

                        readonly property bool current: root.currentPath === modelData.path
                        readonly property bool removable: sectionColumn.modelData.removable === true

                        width: parent.width
                        height: 34
                        radius: Style.cornerRadius
                        color: current ? Style.primaryHover : itemHover.containsMouse ? Style.surfaceHover : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Style.spacingM
                            spacing: Style.spacingS

                            DankIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: parent.parent.modelData.icon
                                size: Style.iconSize - 4
                                color: parent.parent.current ? Style.primary : Style.surfaceText
                            }

                            StyledText {
                                // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                                // them and overlaps the row below.
                                wrapMode: Text.NoWrap
                                anchors.verticalCenter: parent.verticalCenter
                                // Leave room for the remove button on bookmarks.
                                width: parent.width - Style.iconSize - Style.spacingS - 32
                                elide: Text.ElideMiddle
                                text: parent.parent.modelData.name
                                font.pixelSize: Style.fontSizeSmall
                                font.weight: parent.parent.current ? Font.Medium : Font.Normal
                                color: parent.parent.current ? Style.primary : Style.surfaceText
                            }
                        }

                        MouseArea {
                            id: itemHover

                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (parent.modelData.path === root.trashPath)
                                        root.openTrashMenu(itemHover, mouse.x, mouse.y);
                                    return;
                                }
                                root.locationSelected(parent.modelData.path);
                            }
                        }

                        DankActionButton {
                            anchors.right: parent.right
                            anchors.rightMargin: Style.spacingXS
                            anchors.verticalCenter: parent.verticalCenter
                            visible: parent.removable && (itemHover.containsMouse || hovered)
                            buttonSize: 24
                            iconSize: Style.iconSizeSmall - 2
                            iconName: "close"
                            onClicked: root.bookmarkRemoved(parent.modelData.path)
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: trashMenu

        width: 184
        height: actionRow.implicitHeight + Style.spacingS * 2
        padding: Style.spacingS
        modal: false
        z: 200
        closePolicy: Popup.CloseOnEscape

        onOpened: outsideClickTimer.start()
        onClosed: closePolicy = Popup.CloseOnEscape

        Timer {
            id: outsideClickTimer

            interval: 100
            onTriggered: trashMenu.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
        }

        background: Rectangle {
            color: Style.floatingSurface
            radius: Style.cornerRadius
            border.color: Style.withAlpha(Style.outline, 0.08)
            border.width: 1
        }

        contentItem: Rectangle {
            id: actionRow

            implicitHeight: 32
            radius: Style.cornerRadius
            color: actionArea.containsMouse ? Style.withAlpha(Style.error, 0.12) : "transparent"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Style.spacingS
                anchors.right: parent.right
                anchors.rightMargin: Style.spacingS
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.spacingS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "delete_sweep"
                    size: 16
                    color: actionArea.containsMouse ? Style.error : Style.surfaceText
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 16 - Style.spacingS
                    text: I18n.tr("Empty Trash…")
                    font.pixelSize: Style.fontSizeSmall
                    color: actionArea.containsMouse ? Style.error : Style.surfaceText
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: actionArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    trashMenu.close();
                    root.emptyTrashRequested();
                }
            }
        }
    }
}
