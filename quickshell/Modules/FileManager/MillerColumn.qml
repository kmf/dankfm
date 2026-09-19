import QtQuick
import Qt.labs.folderlistmodel
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import "FileIcons.js" as FileIcons

Item {
    id: root

    required property var owner
    required property int column
    required property string path

    readonly property bool isActive: owner.activeColumn === column
    readonly property int selectedIndex: owner.selectedIndices[column] ?? -1
    readonly property var folderModel: owner.modelAt(column)

    Rectangle {
        anchors.fill: parent
        color: root.isActive ? Style.surfaceContainerLow : Style.surface

        Behavior on color {
            ColorAnimation {
                duration: Style.shortDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Style.standardEasing
            }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Item {
            width: parent.width
            height: 30

            StyledText {
                // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                // them and overlaps the row below.
                wrapMode: Text.NoWrap
                anchors.left: parent.left
                anchors.leftMargin: Style.spacingM
                anchors.verticalCenter: parent.verticalCenter
                text: root.owner.displayName(root.path)
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall
                font.weight: root.isActive ? Font.Medium : Font.Normal
                color: root.isActive ? Style.primary : Style.surfaceTextMedium
                elide: Text.ElideMiddle
                width: parent.width - Style.spacingM * 2 - 32
            }

            StyledText {
                // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                // them and overlaps the row below.
                wrapMode: Text.NoWrap
                anchors.right: parent.right
                anchors.rightMargin: Style.spacingM
                anchors.verticalCenter: parent.verticalCenter
                text: root.folderModel ? root.folderModel.count : 0
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall
                color: Style.surfaceTextSecondary
            }
        }

        DankListView {
            id: entries

            width: parent.width
            height: Math.max(0, parent.height - 30)
            model: root.folderModel
            currentIndex: root.selectedIndex
            clip: true

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: mouse => {
                    root.owner.openContextMenu(entries, mouse.x, mouse.y, root.path, root.owner.displayName(root.path), true, true);
                }
            }

            delegate: Item {
                required property int index
                required property string fileName
                required property string filePath
                required property bool fileIsDir

                readonly property bool selected: root.owner.isIndexSelected(root.column, index)
                // The cursor is where the keyboard is; with a multi-selection
                // several rows are selected but only one is the cursor.
                readonly property bool isCursor: index === root.selectedIndex

                width: entries.width
                height: 30

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingXS
                    anchors.rightMargin: Style.spacingXS
                    radius: Style.cornerRadius
                    // The selection in an inactive column is the trail showing how
                    // you got here, so it has to stay legible. surfacePressed is
                    // a 12% wash that disappears on a dark theme - with no child
                    // column to give it away (a file has none) the trail simply
                    // looks absent.
                    color: {
                        if (parent.selected)
                            return root.isActive ? Style.primarySelected : Style.surfaceContainerHighest;
                        return hover.containsMouse ? Style.surfaceHover : "transparent";
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingM
                    anchors.rightMargin: Style.spacingS
                    spacing: Style.spacingS

                    DankIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: FileIcons.forEntry(parent.parent.fileName, parent.parent.fileIsDir)
                        size: Style.iconSizeSmall
                        color: parent.parent.selected && root.isActive ? Style.primary : parent.parent.fileIsDir ? Style.surfaceText : Style.surfaceTextMedium
                    }

                    StyledText {
                        // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                        // them and overlaps the row below.
                        wrapMode: Text.NoWrap
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Style.iconSizeSmall - Style.spacingS - 20
                        text: parent.parent.fileName
                        font.pixelSize: Style.fontSizeSmall
                        font.weight: parent.parent.selected ? Font.Medium : Font.Normal
                        color: parent.parent.selected && root.isActive ? Style.primary : Style.surfaceText
                        elide: Text.ElideMiddle
                    }
                }

                DankIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: Style.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    visible: parent.fileIsDir
                    name: "chevron_right"
                    size: Style.iconSizeSmall - 2
                    color: Style.surfaceTextSecondary
                }

                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: mouse => {
                        if (mouse.button === Qt.LeftButton && (mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))) {
                            root.owner.activeColumn = root.column;
                            if (mouse.modifiers & Qt.ControlModifier)
                                root.owner.toggleSelection(root.column, parent.index);
                            else
                                root.owner.extendSelection(root.column, parent.index);
                            root.owner.takeFocus();
                            mouse.accepted = true;
                            return;
                        }
                        if (mouse.button !== Qt.RightButton)
                            return;
                        root.owner.select(root.column, parent.index);
                        // Anchor the menu to the column, not the 30px row, so it
                        // has somewhere to be clamped into.
                        const point = mapToItem(entries, mouse.x, mouse.y);
                        root.owner.openContextMenu(entries, point.x, point.y, parent.filePath, parent.fileName, parent.fileIsDir);
                    }
                    onClicked: mouse => {
                        if (mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier))
                            return;
                        root.owner.select(root.column, parent.index);
                        root.owner.takeFocus();
                    }
                    onDoubleClicked: {
                        root.owner.select(root.column, parent.index);
                        root.owner.activate();
                        root.owner.takeFocus();
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.dividerWidth
        color: Style.outlineMedium
    }
}
