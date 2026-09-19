import QtQuick
import Quickshell.Io
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import "FileIcons.js" as FileIcons
import "SyntaxHighlight.js" as Syntax

Rectangle {
    id: root

    property var entry: null
    required property var git
    required property var trash
    property bool inTrash: false

    signal diffRequested

    readonly property bool isDir: entry ? entry.isDir : false
    readonly property bool isImage: entry && !isDir && FileIcons.isImage(entry.name)
    readonly property bool tooLarge: entry && !isDir && entry.size > 512 * 1024
    readonly property bool wantText: entry && !isDir && !isImage && !tooLarge && (FileIcons.isText(entry.name) || entry.size < 128 * 1024)
    readonly property bool showText: wantText && previewReady && !previewBinary
    property string previewText: ""
    property bool previewReady: false
    property bool previewBinary: false

    color: Style.nestedSurface
    clip: true

    onEntryChanged: {
        previewText = "";
        previewReady = false;
        previewBinary = false;
    }

    FileView {
        id: previewFile

        path: root.wantText && root.entry ? root.entry.path : ""
        printErrors: false
        onLoaded: {
            const sample = text();
            root.previewBinary = !Syntax.isProbablyText(sample);
            root.previewText = root.previewBinary ? "" : sample;
            root.previewReady = true;
        }
        onLoadFailed: {
            root.previewText = "";
            root.previewBinary = false;
            root.previewReady = true;
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.dividerWidth
        color: Style.outlineMedium
    }

    StyledText {
        anchors.centerIn: parent
        visible: !root.entry
        text: I18n.tr("Nothing selected")
        font.pixelSize: Style.fontSizeSmall
        color: Style.surfaceTextSecondary
        wrapMode: Text.NoWrap
    }

    Item {
        anchors.fill: parent
        anchors.margins: Style.spacingL
        visible: root.entry !== null

        Column {
            id: identity

            anchors.top: parent.top
            width: parent.width
            spacing: Style.spacingXXS

            StyledText {
                width: parent.width
                text: root.entry ? root.entry.name : ""
                font.pixelSize: Style.fontSizeMedium
                font.weight: Font.Medium
                color: Style.surfaceText
                elide: Text.ElideMiddle
                wrapMode: Text.NoWrap
            }

            StyledText {
                text: {
                    if (!root.entry)
                        return "";
                    if (root.entry.isDir)
                        return I18n.tr("Folder");
                    if (root.tooLarge)
                        return FileIcons.formatSize(root.entry.size) + " · " + I18n.tr("too large to preview");
                    return FileIcons.formatSize(root.entry.size);
                }
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall
                color: Style.surfaceTextSecondary
                wrapMode: Text.NoWrap
            }
        }

        Item {
            id: body

            anchors.top: identity.bottom
            anchors.topMargin: Style.spacingM
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.bottomMargin: Style.spacingM
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: Style.cornerRadiusM
                color: Style.surfaceContainerHighest
                visible: !root.showText
            }

            DankIcon {
                anchors.centerIn: parent
                visible: !thumbnail.visible && !root.showText
                name: root.entry ? FileIcons.forEntry(root.entry.name, root.entry.isDir) : "file_present"
                size: Style.iconSizeLarge * 2
                color: Style.surfaceTextSecondary
            }

            Image {
                id: thumbnail

                anchors.fill: parent
                visible: root.isImage && status === Image.Ready
                source: root.isImage ? "file://" + root.entry.path : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                mipmap: true
                sourceSize.width: Math.round(width)
                sourceSize.height: Math.round(height)
            }

            TextPreview {
                anchors.fill: parent
                anchors.margins: Style.spacingS
                visible: root.showText
                sourceText: root.git.dirty && root.git.diffText.length > 0 ? root.git.diffText : root.previewText
                fileName: root.entry ? root.entry.name : ""
                language: root.git.dirty && root.git.diffText.length > 0 ? "diff" : ""
            }
        }

        Column {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Style.spacingM

            Rectangle {
                width: parent.width
                height: Style.dividerWidth
                color: Style.outlineMedium
                visible: root.git.inRepo
            }

            GitStatusBlock {
                width: parent.width
                git: root.git
                onDiffRequested: root.diffRequested()
            }

            Rectangle {
                width: parent.width
                height: Style.dividerWidth
                color: Style.outlineMedium
            }

            Repeater {
                model: root.inTrash && root.trash.originalPath ? [
                    {
                        "label": I18n.tr("Deleted"),
                        "value": root.trash.deletedAt
                    },
                    {
                        "label": I18n.tr("From"),
                        "value": root.trash.originalPath
                    }
                ] : root.entry ? [
                    {
                        "label": I18n.tr("Modified"),
                        "value": Qt.formatDateTime(root.entry.modified, "d MMM yyyy  HH:mm")
                    },
                    {
                        "label": I18n.tr("Path"),
                        "value": root.entry.path
                    }
                ] : []

                Row {
                    required property var modelData

                    width: parent.width
                    spacing: Style.spacingS

                    StyledText {
                        width: 76
                        text: parent.modelData.label
                        font.pixelSize: Style.fontSizeSmall
                        color: Style.surfaceTextSecondary
                        wrapMode: Text.NoWrap
                    }

                    StyledText {
                        width: parent.width - 76 - Style.spacingS
                        text: parent.modelData.value
                        font.family: Fonts.mono
                        font.pixelSize: Style.fontSizeSmall
                        color: Style.surfaceText
                        wrapMode: Text.WordWrap
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }
}
