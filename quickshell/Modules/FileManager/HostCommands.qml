pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Every real action this app takes is a command: gio for the trash, xdg-open
// and gtk-launch to open things, git for the preview block, a terminal
// emulator, and the shell snippets that probe paths.
//
// Inside a flatpak all of those would run in the sandbox, against a filesystem
// and an application set that are not the user's. `flatpak-spawn --host` is the
// documented way out, and needs --talk-name=org.freedesktop.Flatpak in the
// manifest's finish-args.
//
// Outside a flatpak this is the identity function.
QtObject {
    id: root

    readonly property string flatpakId: Quickshell.env("FLATPAK_ID") ?? ""
    readonly property bool sandboxed: flatpakId.length > 0

    function wrap(command) {
        if (!sandboxed)
            return command;
        return ["flatpak-spawn", "--host"].concat(command);
    }
}
