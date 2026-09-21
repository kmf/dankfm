import QtQuick
import QtQuick.Controls
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// Right-click menu for an entry.
//
// Modelled on the library's FileBrowserItemContextMenu - same surface, sizing
// and close behaviour - but that one's action list is a readonly property with
// two entries, so it cannot be extended from outside.
Popup {
    id: root

    property string filePath: ""
    property string fileName: ""
    property bool fileIsDir: false
    property bool bookmarked: false
    // Inside the trash the ordinary actions make no sense: there is nothing to
    // rename, and an item is already trashed.
    property bool trashMode: false
    property bool canPaste: false
    // Right-click on empty space in a folder, not on a file row.
    property bool directoryMenu: false

    signal openRequested
    signal openInNewTabRequested
    signal openWithRequested
    signal terminalRequested
    signal copyRequested
    signal cutRequested
    signal pasteRequested
    signal copyPathRequested
    signal bookmarkRequested
    signal renameRequested
    signal newFolderRequested
    signal trashRequested
    signal restoreRequested
    signal deleteForeverRequested
    signal emptyTrashRequested

    readonly property var menuItems: [
        {
            "text": fileIsDir ? I18n.tr("Open") : I18n.tr("Open with default app"),
            "icon": fileIsDir ? "folder_open" : "open_in_new",
            "visible": !directoryMenu,
            "action": () => root.fire(root.openRequested)
        },
        {
            "text": I18n.tr("Open in New Tab"),
            "icon": "tab_new_right",
            "visible": !directoryMenu && fileIsDir,
            "action": () => root.fire(root.openInNewTabRequested)
        },
        {
            "text": I18n.tr("Open with…"),
            "icon": "open_with",
            "visible": !directoryMenu && !fileIsDir,
            "action": () => root.fire(root.openWithRequested)
        },
        {
            "text": I18n.tr("Open terminal here"),
            "icon": "terminal",
            "action": () => root.fire(root.terminalRequested)
        },
        {
            "separator": true
        },
        {
            "text": I18n.tr("Cut"),
            "icon": "content_cut",
            "visible": !trashMode && !directoryMenu,
            "action": () => root.fire(root.cutRequested)
        },
        {
            "text": I18n.tr("Copy"),
            "icon": "content_copy",
            "visible": !directoryMenu,
            "action": () => root.fire(root.copyRequested)
        },
        {
            "text": I18n.tr("Paste"),
            "icon": "content_paste",
            "visible": !trashMode,
            "action": () => root.fire(root.pasteRequested)
        },
        {
            "text": I18n.tr("Copy path"),
            "icon": "content_copy",
            "visible": !directoryMenu,
            "action": () => root.fire(root.copyPathRequested)
        },
        {
            "text": bookmarked ? I18n.tr("Remove bookmark") : I18n.tr("Bookmark"),
            "icon": bookmarked ? "bookmark_remove" : "bookmark_add",
            "visible": fileIsDir && !trashMode,
            "action": () => root.fire(root.bookmarkRequested)
        },
        {
            "separator": true
        },
        {
            "text": I18n.tr("Restore"),
            "icon": "restore_from_trash",
            "visible": trashMode,
            "action": () => root.fire(root.restoreRequested)
        },
        {
            "text": I18n.tr("Rename…"),
            "icon": "edit",
            "visible": !trashMode,
            "action": () => root.fire(root.renameRequested)
        },
        {
            "text": I18n.tr("New folder…"),
            "icon": "create_new_folder",
            "visible": !trashMode,
            "action": () => root.fire(root.newFolderRequested)
        },
        {
            "text": I18n.tr("Move to Trash"),
            "icon": "delete",
            "dangerous": true,
            "visible": !trashMode,
            "action": () => root.fire(root.trashRequested)
        },
        {
            "text": I18n.tr("Delete permanently…"),
            "icon": "delete_forever",
            "dangerous": true,
            "visible": trashMode,
            "action": () => root.fire(root.deleteForeverRequested)
        },
        {
            "text": I18n.tr("Empty Trash…"),
            "icon": "delete_sweep",
            "dangerous": true,
            "visible": trashMode,
            "action": () => root.fire(root.emptyTrashRequested)
        }
    ]

    readonly property var visibleItems: menuItems.filter(item => item.visible !== false)

    function fire(signalToEmit) {
        close();
        signalToEmit();
    }

    function showAt(parentItem, localX, localY, path, name, isDir) {
        if (!parentItem)
            return;

        parent = parentItem;
        filePath = path ?? "";
        fileName = name ?? "";
        fileIsDir = isDir === true;
        x = Math.max(0, Math.min(Math.max(0, parentItem.width - width), localX));
        y = Math.max(0, Math.min(Math.max(0, parentItem.height - height), localY));
        open();
    }

    width: 232
    height: menuColumn.implicitHeight + Style.spacingS * 2
    padding: 0
    modal: false
    clip: false
    z: 200
    closePolicy: Popup.CloseOnEscape

    // Opening on a press means the release that follows would immediately count
    // as a click outside; only start listening for that once it has passed.
    onOpened: outsideClickTimer.start()
    onClosed: closePolicy = Popup.CloseOnEscape

    Timer {
        id: outsideClickTimer

        interval: 100
        onTriggered: root.closePolicy = Popup.CloseOnEscape | Popup.CloseOnPressOutside
    }

    background: Rectangle {
        color: "transparent"
    }

    contentItem: Rectangle {
        color: Style.floatingSurface
        radius: Style.cornerRadius
        border.color: Style.withAlpha(Style.outline, 0.08)
        border.width: 1

        Column {
            id: menuColumn

            anchors.fill: parent
            anchors.margins: Style.spacingS
            spacing: 1

            Repeater {
                model: root.visibleItems

                // Named rather than reached through parent.parent: the row wraps
                // its content twice and the chain is easy to get wrong.
                Item {
                    id: row

                    required property var modelData

                    readonly property bool isSeparator: modelData.separator === true
                    readonly property bool isDangerous: modelData.dangerous === true

                    width: parent.width
                    height: isSeparator ? Style.spacingS + 1 : 32

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.isSeparator
                        width: parent.width
                        height: Style.dividerWidth
                        color: Style.outlineMedium
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: !row.isSeparator
                        radius: Style.cornerRadius
                        color: {
                            if (!area.containsMouse)
                                return "transparent";
                            return row.isDangerous ? Style.withAlpha(Style.error, 0.12) : Style.widgetBaseHoverColor;
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Style.spacingS
                            anchors.right: parent.right
                            anchors.rightMargin: Style.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Style.spacingS

                            DankIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: row.modelData.icon ?? ""
                                size: 16
                                color: row.isDangerous && area.containsMouse ? Style.error : Style.surfaceText
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 16 - Style.spacingS
                                text: row.modelData.text ?? ""
                                font.pixelSize: Style.fontSizeSmall
                                color: row.isDangerous && area.containsMouse ? Style.error : Style.surfaceText
                                wrapMode: Text.NoWrap
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: area

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: row.modelData.action()
                        }
                    }
                }
            }
        }
    }
}
