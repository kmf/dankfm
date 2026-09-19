pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import QtCore

Singleton {
    id: root

    property var _trashCallback: null

    readonly property url home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property url xdgCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property url cache: `${xdgCache}/dank-qml-common`
    readonly property url imagecache: `${cache}/imagecache`

    function stringify(path: url): string {
        return path.toString().replace(/%20/g, " ");
    }

    function strip(path: url): string {
        return stringify(path).replace("file://", "");
    }

    function mkdir(path: url): void {
        Quickshell.execDetached(["mkdir", "-p", strip(path)]);
    }

    function resolveIconPath(iconName: string): string {
        if (!iconName)
            return "";
        if (iconName.startsWith("/"))
            return "file://" + iconName;
        return Quickshell.iconPath(iconName, true);
    }

    function trashPath(path: string, callback): void {
        if (!path)
            return;
        _trashCallback = callback ?? null;
        trashProcess.targetPath = path;
        trashProcess.running = true;
    }

    function copyPathToClipboard(path: string): void {
        Quickshell.clipboardText = path;
    }

    // Trashing is the one thing this stub actually shells out for, so it needs
    // the same sandbox escape the rest of the app uses - inside a flatpak,
    // `gio trash` would move the file to the sandbox's trash.
    readonly property bool sandboxed: (Quickshell.env("FLATPAK_ID") ?? "").length > 0

    Process {
        id: trashProcess

        property string targetPath: ""

        command: root.sandboxed ? ["flatpak-spawn", "--host", "gio", "trash", targetPath] : ["gio", "trash", targetPath]
        onExited: exitCode => {
            const cb = root._trashCallback;
            root._trashCallback = null;
            if (cb)
                cb(exitCode === 0);
        }
    }

    Component.onCompleted: mkdir(imagecache)
}
