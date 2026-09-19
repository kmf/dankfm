pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common

// The filesystem-changing operations behind the context menu.
//
// Every one of them can fail for reasons the UI cannot predict - permissions, a
// name that already exists, a device that went away - so each reports back
// rather than assuming success, and the view refreshes only the directory that
// actually changed.
QtObject {
    id: root

    // Commands run on the host when this app is sandboxed - see HostCommands.
    required property var host

    // Emitted with the directory whose contents changed, so the caller can
    // refresh just that folder's model.
    signal changed(string directory)
    // A path the view may currently be sitting in has moved or gone away. The
    // caller needs these separately from `changed`: refreshing the parent
    // listing does not help a column that is pointing at the old path.
    signal renamed(string oldPath, string newPath)
    signal removed(string path)
    // The path as it was before trashing, so it can be put back.
    signal trashed(string originalPath)
    signal transferred(int count, bool cut, bool ok)
    signal failed(string message)

    function parentOf(path) {
        return path.replace(/\/[^/]+\/?$/, "") || "/";
    }

    function baseName(path) {
        return path.split("/").filter(s => s.length > 0).pop() ?? "";
    }

    function validateName(name) {
        if (!name || !name.trim())
            return I18n.tr("Name cannot be empty");
        if (name.indexOf("/") !== -1)
            return I18n.tr("Name cannot contain '/'");
        if (name === "." || name === "..")
            return I18n.tr("Reserved name");
        return "";
    }

    // mv -n rather than mv: refusing to clobber is the whole point, and the
    // shell's own test for an existing target would race with the move.
    function rename(path, newName) {
        const problem = validateName(newName);
        if (problem) {
            failed(problem);
            return;
        }
        if (newName === baseName(path))
            return;

        const directory = parentOf(path);
        const target = directory === "/" ? "/" + newName : directory + "/" + newName;
        run(["sh", "-c", 'test ! -e "$2" && mv -n -- "$1" "$2"', "sh", path, target], directory, I18n.tr("Could not rename to %1").arg(newName), () => root.renamed(path, target));
    }

    function createFolder(directory, name) {
        const problem = validateName(name);
        if (problem) {
            failed(problem);
            return;
        }

        const target = directory === "/" ? "/" + name : directory + "/" + name;
        // Plain mkdir, not mkdir -p: an existing folder should be reported, not
        // silently accepted.
        run(["mkdir", "--", target], directory, I18n.tr("Could not create %1").arg(name));
    }

    function trash(path) {
        const directory = parentOf(path);
        Paths.trashPath(path, ok => {
            if (ok) {
                root.trashed(path);
                root.removed(path);
                root.changed(directory);
            } else
                root.failed(I18n.tr("Could not move %1 to trash").arg(root.baseName(path)));
        });
    }

    // Copy or move `paths` into destDir. Existing names get " (copy)" rather
    // than being overwritten. A folder cannot be pasted into itself.
    function transfer(paths, destDir, cut) {
        if (!paths || paths.length === 0) {
            failed(I18n.tr("Nothing to paste"));
            return;
        }
        if (!destDir) {
            failed(I18n.tr("No destination"));
            return;
        }

        const command = ["sh", "-c", transferScript, "sh", destDir, cut ? "cut" : "copy"].concat(paths);
        Proc.runCommand(null, host.wrap(command), (output, exitCode) => {
            const lines = (output || "").split("\n").filter(line => line.indexOf("\t") !== -1);
            const seenParents = {};
            for (const line of lines) {
                const tab = line.indexOf("\t");
                const src = line.slice(0, tab);
                const dest = line.slice(tab + 1);
                if (cut)
                    root.renamed(src, dest);
                const srcParent = root.parentOf(src);
                if (!seenParents[srcParent]) {
                    seenParents[srcParent] = true;
                    root.changed(srcParent);
                }
            }
            root.changed(destDir);
            const ok = exitCode === 0;
            root.transferred(lines.length, cut === true, ok);
            if (!ok && lines.length === 0)
                root.failed(cut ? I18n.tr("Could not move items") : I18n.tr("Could not copy items"));
        }, 0, Proc.noTimeout, root);
    }

    // $1 destination directory, $2 copy|cut, remaining args are sources.
    // Prints src<TAB>dest for each success so the caller can refresh both sides.
    readonly property string transferScript: 'dest="$1"
mode="$2"
shift 2
if [ ! -d "$dest" ]; then
    echo "not a directory" >&2
    exit 1
fi
unique_target() {
    dir=$1
    name=$2
    if [ "$dir" = "/" ]; then
        target="/$name"
    else
        target="$dir/$name"
    fi
    if [ ! -e "$target" ]; then
        printf "%s\\n" "$target"
        return
    fi
    stem=$name
    ext=
    case $name in
        .*) ;;
        *.*)
            ext=.${name##*.}
            stem=${name%.*}
            ;;
    esac
    n=1
    while :; do
        if [ "$n" -eq 1 ]; then
            cand_name="${stem} (copy)${ext}"
        else
            cand_name="${stem} (copy ${n})${ext}"
        fi
        if [ "$dir" = "/" ]; then
            cand="/$cand_name"
        else
            cand="$dir/$cand_name"
        fi
        if [ ! -e "$cand" ]; then
            printf "%s\\n" "$cand"
            return
        fi
        n=$((n + 1))
    done
}
status=0
for src in "$@"; do
    [ -e "$src" ] || { status=1; continue; }
    case "$dest" in
        "$src"|"$src"/*)
            status=1
            continue
            ;;
    esac
    parent=$(dirname -- "$src")
    base=$(basename -- "$src")
    if [ "$mode" = cut ] && [ "$parent" = "$dest" ]; then
        continue
    fi
    target=$(unique_target "$dest" "$base") || { status=1; continue; }
    if [ "$mode" = cut ]; then
        mv -- "$src" "$target" || { status=1; continue; }
    else
        cp -a -- "$src" "$target" || { status=1; continue; }
    fi
    printf "%s\\t%s\\n" "$src" "$target"
done
exit $status
'

    function run(command, directory, errorMessage, onSuccess) {
        Proc.runCommand(null, host.wrap(command), (output, exitCode) => {
            if (exitCode !== 0) {
                root.failed(errorMessage);
                return;
            }
            if (onSuccess)
                onSuccess();
            root.changed(directory);
        }, 0, 10000, root);
    }
}
