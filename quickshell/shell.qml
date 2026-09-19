//@ pragma UseQApplication
//@ pragma AppId com.danklinux.dankfm

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common as App
import qs.DankCommon.Common as DC
import qs.Services as AppServices
import qs.Services

// Standalone entry. The Go supervisor (`dfm`) sets DANKFM_SOCKET and talks to
// DankFmService; `qs -p quickshell` still runs without it (window quits on close).
ShellRoot {
    id: shellRoot

    readonly property bool supervised: (Quickshell.env("DANKFM_SOCKET") ?? "").length > 0
    readonly property bool startHidden: Quickshell.env("DANKFM_START_HIDDEN") === "1"

    Component.onCompleted: {
        DC.Style.theme = App.Theme;
        DC.Style.settings = App.SettingsData;
        DC.I18n.backend = App.I18n;
        DC.Paths.backend = App.Paths;
        DC.Log.backend = AppServices.Log;
        DC.Host.session = AppServices.SessionService;
        DC.Host.cache = App.CacheData;
    }

    function ownToplevel() {
        const toplevels = ToplevelManager.toplevels;
        if (!toplevels || !toplevels.values)
            return null;
        for (const t of toplevels.values) {
            if (t.appId === "com.danklinux.dankfm")
                return t;
        }
        return null;
    }

    function focusToplevel() {
        const t = ownToplevel();
        if (!t)
            return;
        if (t.minimized)
            t.minimized = false;
        t.activate();
    }

    function showAndFocus() {
        win.visible = true;
        win.activate();
        focusRetry.restart();
    }

    function handleWindowAction(action) {
        switch (action) {
        case "show":
            showAndFocus();
            break;
        case "hide":
            win.visible = false;
            break;
        case "toggle":
            if (win.visible)
                win.visible = false;
            else
                showAndFocus();
            break;
        }
    }

    Timer {
        id: focusRetry
        interval: 150
        repeat: false
        onTriggered: shellRoot.focusToplevel()
    }

    Connections {
        target: DankFmService

        function onConnectedChanged() {
            if (DankFmService.connected)
                DankFmService.reportPath(win.currentPath);
        }

        function onWindowActionRequested(action) {
            shellRoot.handleWindowAction(action);
        }

        function onBrowseRequested(path) {
            win.browse(path);
            shellRoot.focusToplevel();
        }
    }

    DankFmWindow {
        id: win

        quitOnClose: !shellRoot.supervised
        visible: !shellRoot.supervised || !shellRoot.startHidden

        onCurrentPathChanged: DankFmService.reportPath(currentPath)
    }
}
