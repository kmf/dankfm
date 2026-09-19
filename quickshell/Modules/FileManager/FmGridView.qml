import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Modals.FileBrowser
import qs.DankCommon.Widgets

// Thumbnail-first view of the active directory, on the shared FileBrowser grid
// delegate - the same tiles the picker modal uses, including its image and
// video thumbnails.
Item {
    id: root

    required property var owner

    readonly property var folderModel: owner.modelAt(owner.activeColumn)
    readonly property int selectedIndex: owner.selectedIndices[owner.activeColumn] ?? -1

    // Matches FileBrowserGridDelegate's own sizing: the icon box plus room for
    // the label beneath it.
    readonly property var iconSizes: [80, 120, 160, 200]
    property int iconSizeIndex: 1
    readonly property int cellWidth: iconSizes[iconSizeIndex] + 16
    readonly property int cellHeight: iconSizes[iconSizeIndex] + 48

    onSelectedIndexChanged: tiles.positionViewAtIndex(selectedIndex, GridView.Contain)

    Rectangle {
        anchors.fill: parent
        color: Style.surface
    }

    DankGridView {
        id: tiles

        anchors.fill: parent
        anchors.margins: Style.spacingM
        cellWidth: root.cellWidth
        cellHeight: root.cellHeight
        cacheBuffer: root.cellHeight * 4
        model: root.folderModel
        currentIndex: root.selectedIndex
        clip: true

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.RightButton
            onClicked: mouse => {
                const dir = root.owner.currentDir;
                root.owner.openContextMenu(tiles, mouse.x, mouse.y, dir, root.owner.displayName(dir), true, true);
            }
        }

        // Wrapped for the same reasons as the list view: a highlight behind the
        // tile for the rest of a multi-selection, and an overlay that takes the
        // modified clicks the shared delegate cannot report.
        delegate: Item {
            id: cell

            required property int index
            required property bool fileIsDir
            required property string filePath
            required property string fileName

            readonly property bool multiSelected: root.owner.isIndexSelected(root.owner.activeColumn, index) && index !== root.selectedIndex

            width: root.cellWidth
            height: root.cellHeight

            Rectangle {
                anchors.fill: tile
                radius: Style.cornerRadius
                color: cell.multiSelected ? Style.surfaceContainerHighest : "transparent"
            }

            FileBrowserGridDelegate {
                id: tile

                index: cell.index
                fileIsDir: cell.fileIsDir
                filePath: cell.filePath
                fileName: cell.fileName
                iconSizes: root.iconSizes
                iconSizeIndex: root.iconSizeIndex
                selectedIndex: root.selectedIndex
                keyboardNavigationActive: true
                onItemClicked: itemIndex => root.owner.clickEntry(itemIndex, Qt.NoModifier)
                onItemContextMenuRequested: (sender, localX, localY, path, name, isDir) => {
                    if (!root.owner.isIndexSelected(root.owner.activeColumn, sender.index))
                        root.owner.select(root.owner.activeColumn, sender.index);
                    const point = sender.mapToItem(tiles, localX, localY);
                    root.owner.openContextMenu(tiles, point.x, point.y, path, name, isDir);
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: mouse => {
                    if (!(mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))) {
                        mouse.accepted = false;
                        return;
                    }
                    root.owner.clickEntry(cell.index, mouse.modifiers);
                    mouse.accepted = true;
                }
            }
        }
    }

    StyledText {
        // Fixed-height rows: StyledText defaults to WordWrap, which overflows
        // them and overlaps the row below.
        wrapMode: Text.NoWrap
        anchors.centerIn: parent
        visible: tiles.count === 0
        text: I18n.tr("Empty folder")
        font.pixelSize: Style.fontSizeSmall
        color: Style.surfaceTextSecondary
    }
}
