pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Bookmarked directories, persisted as JSON under XDG state.
//
// The file is watched, so bookmarks added in one window show up in another -
// and editing the file by hand works too.
QtObject {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/dankfm"
    readonly property string filePath: stateDir + "/bookmarks.json"

    property var paths: []
    property bool loaded: false

    function has(path) {
        return paths.indexOf(path) !== -1;
    }

    function add(path) {
        if (!path || has(path))
            return;
        paths = paths.concat([path]);
        save();
    }

    function remove(path) {
        if (!has(path))
            return;
        paths = paths.filter(entry => entry !== path);
        save();
    }

    function toggle(path) {
        has(path) ? remove(path) : add(path);
    }

    function save() {
        loaded = true;
        file.setText(JSON.stringify({
            "bookmarks": paths
        }, null, 2) + "\n");
    }

    function parse(text) {
        try {
            const doc = JSON.parse(text);
            const list = Array.isArray(doc) ? doc : doc?.bookmarks;
            paths = Array.isArray(list) ? list.filter(entry => typeof entry === "string") : [];
        } catch (e) {
            console.warn("Bookmarks: could not parse", root.filePath, e);
            paths = [];
        }
        loaded = true;
    }

    property FileView file: FileView {
        path: root.filePath
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: root.parse(text())
        // No file yet is the normal first-run state, not an error.
        onLoadFailed: root.loaded = true
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", stateDir])
}
