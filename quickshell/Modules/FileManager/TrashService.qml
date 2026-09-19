pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.DankCommon.Common

// The XDG trash: browsing it, and the operations that only make sense inside it.
//
// `files/` holds the trashed items under their original basenames (suffixed on
// collision) and `info/<name>.trashinfo` records where each came from. Only
// top-level entries have an info file, so a path deeper inside a trashed folder
// reports the metadata of the folder it belongs to.
QtObject {
    id: root

    // Commands run on the host when sandboxed - see HostCommands.
    required property var host

    readonly property string trashDir: Quickshell.env("HOME") + "/.local/share/Trash"
    readonly property string filesDir: trashDir + "/files"

    property string path: ""
    property string originalPath: ""
    property string deletedAt: ""

    signal changed
    signal failed(string message)

    function isInTrash(candidate) {
        return candidate === filesDir || candidate.startsWith(filesDir + "/");
    }

    // The top-level entry a path belongs to - the only level the trash keeps
    // metadata for.
    function entryFor(candidate) {
        if (!isInTrash(candidate) || candidate === filesDir)
            return "";
        return candidate.slice(filesDir.length + 1).split("/")[0];
    }

    onPathChanged: load(path)

    function load(candidate) {
        originalPath = "";
        deletedAt = "";

        const entry = entryFor(candidate);
        if (!entry)
            return;

        Proc.runCommand("dfm-trashinfo", host.wrap(["sh", "-c", 'cat "$1/info/$2.trashinfo" 2>/dev/null', "sh", trashDir, entry]), (output, exitCode) => {
            if (exitCode !== 0)
                return;
            for (const line of output.split("\n")) {
                if (line.startsWith("Path="))
                    // .trashinfo percent-encodes the original path.
                    root.originalPath = decodeURIComponent(line.slice(5));
                else if (line.startsWith("DeletionDate="))
                    root.deletedAt = line.slice(13).replace("T", " ");
            }
        }, 0, 5000, root);
    }

    // `gio trash --restore` is not an option: it insists on a trash:/// URI and
    // then needs the gvfs trash backend, which reports "Operation not
    // supported" where gvfsd-trash is not running. The spec's own recipe works
    // anywhere: read the original path out of the .trashinfo, move the entry
    // back, and drop the metadata.
    function restore(candidate) {
        const entry = entryFor(candidate);
        if (!entry) {
            failed(I18n.tr("Not a trashed item"));
            return;
        }

        Proc.runCommand(null, host.wrap(["sh", "-c", 'cat "$1/info/$2.trashinfo" 2>/dev/null', "sh", trashDir, entry]), (output, exitCode) => {
            if (exitCode !== 0) {
                root.failed(I18n.tr("No trash record for %1").arg(entry));
                return;
            }

            let target = "";
            for (const line of output.split("\n")) {
                if (line.startsWith("Path="))
                    target = decodeURIComponent(line.slice(5));
            }

            if (!target) {
                root.failed(I18n.tr("No original location recorded for %1").arg(entry));
                return;
            }
            root.moveBack(entry, target);
        }, 0, 5000, root);
    }

    // Finds the trashed entry that came from `original` and puts it back. The
    // trash renames on collision, so the entry is not simply the basename - it
    // has to be looked up by the Path recorded in the .trashinfo.
    //
    // GLib escapes that path the way a URI path is escaped: slashes survive,
    // everything else is percent-encoded. encodeURIComponent per segment
    // reproduces it.
    function restoreOriginal(original) {
        const encoded = original.split("/").map(encodeURIComponent).join("/");
        const script = ['match=$(grep -lFx "Path=$2" "$1"/info/*.trashinfo 2>/dev/null | xargs -r ls -t | head -n1)', '[ -n "$match" ] || exit 1', 'base=${match##*/}', 'printf "%s\n" "${base%.trashinfo}"'].join("\n");

        Proc.runCommand(null, host.wrap(["sh", "-c", script, "sh", trashDir, encoded]), (output, exitCode) => {
            const entry = output.trim();
            if (exitCode !== 0 || !entry) {
                root.failed(I18n.tr("Nothing in the trash came from %1").arg(original));
                return;
            }
            root.moveBack(entry, original);
        }, 0, 5000, root);
    }

    // Refuses to overwrite: restoring is not worth losing whatever took the
    // name in the meantime.
    function moveBack(entry, target) {
        restoredTo = target;
        run(["sh", "-c", 'test ! -e "$3" && mkdir -p -- "$(dirname "$3")" && mv -n -- "$1/files/$2" "$3" && rm -f -- "$1/info/$2.trashinfo"', "sh", trashDir, entry, target], I18n.tr("Could not restore to %1").arg(target));
    }

    property string restoredTo: ""

    // Removes the entry and its metadata together; leaving the .trashinfo behind
    // makes the trash inconsistent.
    function deleteForever(candidate) {
        const entry = entryFor(candidate);
        if (!entry) {
            failed(I18n.tr("Not a trashed item"));
            return;
        }
        run(["sh", "-c", 'rm -rf -- "$1/files/$2" "$1/info/$2.trashinfo"', "sh", trashDir, entry], I18n.tr("Could not delete %1").arg(entry));
    }

    function empty() {
        run(["gio", "trash", "--empty"], I18n.tr("Could not empty the trash"));
    }

    function run(command, errorMessage) {
        Proc.runCommand(null, host.wrap(command), (output, exitCode) => {
            if (exitCode === 0)
                root.changed();
            else
                root.failed(errorMessage);
        }, 0, 15000, root);
    }
}
