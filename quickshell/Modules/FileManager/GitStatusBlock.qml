import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// The preview pane's git section: what changed, on which branch, and the two
// actions the design canvas puts there.
Column {
    id: root

    required property var git

    signal diffRequested

    visible: git.inRepo
    spacing: Style.spacingS

    Row {
        width: parent.width
        spacing: Style.spacingS

        DankIcon {
            anchors.verticalCenter: parent.verticalCenter
            name: "account_tree"
            size: Style.iconSizeSmall
            color: root.git.dirty ? Style.primary : Style.surfaceTextSecondary
        }

        StyledText {
            // Fixed-height rows: StyledText defaults to WordWrap, which overflows
            // them and overlaps the row below.
            wrapMode: Text.NoWrap
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - Style.iconSizeSmall - counts.width - Style.spacingS * 2
            text: root.git.stateLabel
            font.pixelSize: Style.fontSizeSmall
            font.weight: Font.Medium
            color: Style.surfaceText
            elide: Text.ElideRight
        }

        Row {
            id: counts

            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.spacingXS

            // The canvas uses green here; the theme has no success role, so
            // additions take the primary accent and removals the error role.
            StyledText {
                // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                // them and overlaps the row below.
                wrapMode: Text.NoWrap
                visible: root.git.addedLines > 0
                text: "+" + root.git.addedLines
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall
                color: Style.primary
            }

            StyledText {
                // Fixed-height rows: StyledText defaults to WordWrap, which overflows
                // them and overlaps the row below.
                wrapMode: Text.NoWrap
                visible: root.git.removedLines > 0
                text: "−" + root.git.removedLines
                font.family: Fonts.mono
                font.pixelSize: Style.fontSizeSmall
                color: Style.error
            }
        }
    }

    StyledText {
        // Fixed-height rows: StyledText defaults to WordWrap, which overflows
        // them and overlaps the row below.
        wrapMode: Text.NoWrap
        width: parent.width
        text: root.git.branchLabel
        font.family: Fonts.mono
        font.pixelSize: Style.fontSizeSmall - 1
        color: Style.surfaceTextSecondary
        elide: Text.ElideRight
    }

    Row {
        spacing: Style.spacingS

        DankButton {
            text: root.git.staged ? I18n.tr("Unstage") : I18n.tr("Stage")
            iconName: root.git.staged ? "remove" : "add"
            buttonHeight: Style.buttonHeightXS
            minimumWidth: 0
            enabled: root.git.dirty && !root.git.loading
            onClicked: root.git.staged ? root.git.unstage() : root.git.stage()
        }

        DankButton {
            text: I18n.tr("Diff")
            iconName: "difference"
            buttonHeight: Style.buttonHeightXS
            minimumWidth: 0
            backgroundColor: Style.surfaceContainerHighest
            textColor: Style.surfaceText
            enabled: root.git.dirty && !root.git.loading
            onClicked: root.diffRequested()
        }
    }
}
