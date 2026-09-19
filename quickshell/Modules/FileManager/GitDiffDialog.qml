import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import "SyntaxHighlight.js" as Syntax

// `git diff HEAD` for the selected path, coloured per line.
DankDialog {
    id: root

    required property var git
    property string fileName: ""

    readonly property var colors: ({
            "text": Style.surfaceTextMedium,
            "comment": Style.surfaceTextSecondary,
            "keyword": Style.primary,
            "string": Style.tertiary,
            "number": Style.secondary,
            "type": Style.secondary,
            "punct": Style.surfaceTextMedium,
            "add": Style.primary,
            "del": Style.error,
            "hunk": Style.secondary,
            "meta": Style.surfaceTextSecondary
        })
    readonly property var lines: git.diffText.length > 0 ? Syntax.highlightText(git.diffText, "diff", colors, 800) : []
    readonly property int rowHeight: Math.round((Style.fontSizeSmall - 1) * 1.6)

    embedded: false
    title: I18n.tr("Diff") + (fileName ? " · " + fileName : "")
    iconName: "difference"
    supportingText: git.branchLabel
    maximumWidth: 900
    acceptEnabled: false

    DankListView {
        width: parent.width
        height: Math.min(460, Math.max(40, root.lines.length * root.rowHeight))
        model: root.lines
        clip: true

        delegate: StyledText {
            required property var modelData

            width: ListView.view.width
            height: root.rowHeight
            text: modelData
            textFormat: Text.RichText
            font.family: Fonts.mono
            font.pixelSize: Style.fontSizeSmall - 1
            color: Style.surfaceText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
    }

    StyledText {
        width: parent.width
        visible: root.lines.length === 0
        text: root.git.diffLoading ? I18n.tr("Loading diff…") : I18n.tr("No diff against HEAD")
        font.pixelSize: Style.fontSizeSmall
        color: Style.surfaceTextSecondary
        wrapMode: Text.NoWrap
    }
}
