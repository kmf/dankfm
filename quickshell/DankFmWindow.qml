import QtQuick
import Quickshell
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import "./Modules/FileManager"

// Colours come from Style rather than an app singleton, so the window themes
// against the Common/ stub standalone and against a real Theme if one is injected.
FloatingWindow {
    id: win

    property bool isFloatingWindowSurface: true
    property bool quitOnClose: false

    readonly property string currentPath: content.targetDir

    function activate() {
        visible = true;
        content.takeFocus();
    }

    function toggle() {
        if (visible)
            visible = false;
        else
            activate();
    }

    function browse(path) {
        activate();
        content.revealPath(path);
    }

    title: "DankFM"
    implicitWidth: 1360
    implicitHeight: 872
    minimumSize: Qt.size(720, 480)
    color: Style.surface
    visible: false

    onVisibleChanged: {
        if (visible)
            Qt.callLater(content.takeFocus);
    }

    FloatingWindowControls {
        id: controls

        targetWindow: win
    }

    Column {
        anchors.fill: parent
        spacing: 0

        DankWindowHeader {
            id: header

            width: parent.width
            controls: controls
            title: content.windowTitle
            subtitle: content.windowSubtitle
            iconName: "folder_open"
            onCloseRequested: {
                if (win.quitOnClose)
                    Qt.quit();
                else
                    win.visible = false;
            }
        }

        FileManagerContent {
            id: content

            width: parent.width
            height: parent.height - header.height
            onSettingsRequested: {
                settingsLoader.active = true;
                settingsLoader.item.show();
            }
        }
    }

    Loader {
        id: settingsLoader

        active: false
        sourceComponent: FmSettingsWindow {
        }
    }
}
