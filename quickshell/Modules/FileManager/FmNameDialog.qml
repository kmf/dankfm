import QtQuick
import qs.DankCommon.Common
import qs.DankCommon.Widgets

// Prompt for a single name - used for both rename and new folder.
DankDialog {
    id: root

    property string prompt: ""
    property string initialName: ""
    // Names may not contain "/", but this dialog is also used to ask for a
    // command, which may.
    property bool allowSlashes: false
    property string fieldLabel: I18n.tr("Name")

    signal submitted(string name)

    function ask(dialogTitle, dialogPrompt, name, options) {
        title = dialogTitle;
        prompt = dialogPrompt;
        initialName = name;
        allowSlashes = options?.allowSlashes === true;
        fieldLabel = options?.fieldLabel ?? I18n.tr("Name");
        iconName = options?.iconName ?? "edit";
        field.text = name;
        opened = true;
        // The field only exists once the dialog is on screen.
        Qt.callLater(() => {
            field.forceActiveFocus();
            field.selectAll();
        });
    }

    embedded: false
    opened: false
    iconName: "edit"
    supportingText: prompt
    maximumWidth: 460
    acceptEnabled: field.text.trim().length > 0 && (allowSlashes || field.text.indexOf("/") === -1)

    onRejected: opened = false

    DankTextField {
        id: field

        width: parent.width
        outlined: true
        labelText: root.fieldLabel
        onAccepted: {
            if (root.acceptEnabled)
                root.accepted();
        }
    }

    onAccepted: {
        if (!acceptEnabled)
            return;
        opened = false;
        submitted(field.text.trim());
    }

    actions: [
        DankButton {
            text: I18n.tr("Cancel")
            maximumWidth: root.actionWidth
            backgroundColor: Style.surfaceContainerHighest
            textColor: Style.surfaceText
            onClicked: root.rejected()
        },
        DankButton {
            text: I18n.tr("Save")
            maximumWidth: root.actionWidth
            enabled: root.acceptEnabled
            onClicked: root.accepted()
        }
    ]
}
