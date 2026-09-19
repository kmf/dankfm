import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// Confirmation for the operations that cannot be undone.
DankDialog {
    id: root

    property string message: ""
    property string confirmText: I18n.tr("Delete")

    signal confirmed

    function ask(dialogTitle, dialogMessage, buttonText, icon) {
        title = dialogTitle;
        message = dialogMessage;
        confirmText = buttonText ?? I18n.tr("Delete");
        iconName = icon ?? "delete_forever";
        opened = true;
    }

    embedded: false
    opened: false
    iconName: "delete_forever"
    supportingText: message
    maximumWidth: 460
    acceptEnabled: false

    onRejected: opened = false

    actions: [
        DankButton {
            text: I18n.tr("Cancel")
            maximumWidth: root.actionWidth
            backgroundColor: Style.surfaceContainerHighest
            textColor: Style.surfaceText
            onClicked: root.rejected()
        },
        DankButton {
            text: root.confirmText
            maximumWidth: root.actionWidth
            backgroundColor: Style.error
            textColor: Style.surface
            onClicked: {
                root.opened = false;
                root.confirmed();
            }
        }
    ]
}
