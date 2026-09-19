import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Modals.FileBrowser
import qs.DankCommon.Widgets

// Flat list of the active directory, built on the shared FileBrowser list
// delegate so rows look and behave the same here as in the picker modal.
//
// The delegate owns its own row layout, so the sortable header below mirrors
// its trailing column widths rather than driving them. Keep the two in step if
// the delegate changes upstream.
Item {
    id: root

    required property var owner

    readonly property var folderModel: owner.modelAt(owner.activeColumn)
    readonly property int selectedIndex: owner.selectedIndices[owner.activeColumn] ?? -1
    readonly property bool compactLayout: width < Style.smallBreakpoint
    readonly property real sizeColumnWidth: compactLayout ? 56 : 70
    readonly property real dateColumnWidth: 140

    onSelectedIndexChanged: rows.positionViewAtIndex(selectedIndex, ListView.Contain)

    Rectangle {
        anchors.fill: parent
        color: Style.surface
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Item {
            id: header

            width: parent.width
            height: 32

            Row {
                anchors.fill: parent
                anchors.leftMargin: Style.spacingL + Style.spacingS
                anchors.rightMargin: Style.spacingL + Style.spacingS
                spacing: Style.spacingS

                SortHeaderLabel {
                    width: parent.width - root.sizeColumnWidth - (root.compactLayout ? 0 : root.dateColumnWidth + Style.spacingS) - Style.spacingS - 28
                    height: parent.height
                    text: I18n.tr("Name")
                    field: "name"
                    owner: root.owner
                }

                SortHeaderLabel {
                    width: root.sizeColumnWidth + 28
                    height: parent.height
                    text: I18n.tr("Size")
                    field: "size"
                    alignment: Text.AlignRight
                    owner: root.owner
                }

                SortHeaderLabel {
                    width: root.dateColumnWidth
                    height: parent.height
                    visible: !root.compactLayout
                    text: I18n.tr("Modified")
                    field: "modified"
                    alignment: Text.AlignRight
                    owner: root.owner
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Style.dividerWidth
                color: Style.outlineMedium
            }
        }

        DankListView {
            id: rows

            width: parent.width
            height: Math.max(0, parent.height - header.height)
            model: root.folderModel
            currentIndex: root.selectedIndex
            spacing: Style.spacingXXS
            topMargin: Style.spacingXS
            clip: true

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: mouse => {
                    const dir = root.owner.currentDir;
                    root.owner.openContextMenu(rows, mouse.x, mouse.y, dir, root.owner.displayName(dir), true, true);
                }
            }

            // The shared delegate is wrapped rather than used directly: it draws
            // only the cursor row's highlight and its click signal carries no
            // modifiers, so the wrapper adds a highlight behind it for the rest
            // of a multi-selection and an overlay that takes modified clicks.
            delegate: Item {
                id: cell

                required property int index
                required property bool fileIsDir
                required property string filePath
                required property string fileName
                required property var fileModified
                required property int fileSize

                readonly property bool multiSelected: root.owner.isIndexSelected(root.owner.activeColumn, index) && index !== root.selectedIndex

                width: rows.width
                height: 44

                Rectangle {
                    anchors.fill: row
                    radius: Style.cornerRadius
                    color: cell.multiSelected ? Style.surfaceContainerHighest : "transparent"
                }

                FileBrowserListDelegate {
                    id: row

                    width: rows.width - Style.spacingL * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    index: cell.index
                    fileIsDir: cell.fileIsDir
                    filePath: cell.filePath
                    fileName: cell.fileName
                    fileModified: cell.fileModified
                    fileSize: cell.fileSize
                    selectedIndex: root.selectedIndex
                    keyboardNavigationActive: true
                    onItemClicked: itemIndex => root.owner.clickEntry(itemIndex, Qt.NoModifier)
                    onItemContextMenuRequested: (sender, localX, localY, path, name, isDir) => {
                        if (!root.owner.isIndexSelected(root.owner.activeColumn, sender.index))
                            root.owner.select(root.owner.activeColumn, sender.index);
                        const point = sender.mapToItem(rows, localX, localY);
                        root.owner.openContextMenu(rows, point.x, point.y, path, name, isDir);
                    }
                }

                // Plain presses are rejected so they reach the delegate below.
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
    }

    StyledText {
        // Fixed-height rows: StyledText defaults to WordWrap, which overflows
        // them and overlaps the row below.
        wrapMode: Text.NoWrap
        anchors.centerIn: parent
        visible: rows.count === 0
        text: I18n.tr("Empty folder")
        font.pixelSize: Style.fontSizeSmall
        color: Style.surfaceTextSecondary
    }
}
