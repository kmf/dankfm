import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import "SyntaxHighlight.js" as Syntax

Item {
    id: root

    property string sourceText: ""
    property string fileName: ""
    property string language: ""
    property bool wrapLines: true

    readonly property var colors: ({
            "text": Style.surfaceText,
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
    readonly property string resolvedLanguage: language || Syntax.languageFor(fileName)
    readonly property var lines: Syntax.highlightText(sourceText, resolvedLanguage, colors, 400)
    readonly property int rowHeight: Math.round((Style.fontSizeSmall - 1) * 1.55)

    DankListView {
        id: rows

        anchors.fill: parent
        clip: true
        model: root.lines
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
            id: lineRow

            required property int index
            required property var modelData

            width: rows.width
            height: lineLabel.implicitHeight

            StyledText {
                id: gutter

                anchors.left: parent.left
                width: 32
                text: lineRow.index + 1
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall - 2
                color: Style.surfaceTextSecondary
                horizontalAlignment: Text.AlignRight
                wrapMode: Text.NoWrap
            }

            StyledText {
                id: lineLabel

                anchors.left: gutter.right
                anchors.leftMargin: Style.spacingS
                anchors.right: parent.right
                text: parent.modelData
                textFormat: Text.RichText
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall - 1
                color: Style.surfaceText
                wrapMode: root.wrapLines ? Text.Wrap : Text.NoWrap
                elide: root.wrapLines ? Text.ElideNone : Text.ElideRight
            }
        }
    }
}
