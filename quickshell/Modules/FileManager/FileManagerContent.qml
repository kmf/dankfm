import QtCore
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.DankCommon.Common
import qs.DankCommon.Widgets
import "FileIcons.js" as FileIcons

// Miller-column file manager shell.
//
// Column chain invariant: columns[i + 1] is always the directory highlighted in
// columns[i]. Highlighting a directory therefore reveals its child column for
// free, which is what makes the view feel like a column browser rather than a
// stack of independent lists. Selection lives here, not in the delegates, so
// keyboard navigation never has to reach into the ListView.
FocusScope {
    id: root

    LayoutMirroring.enabled: I18n.isRtl
    LayoutMirroring.childrenInherit: true

    readonly property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")

    property var columns: ancestorsOf(homeDir)
    property var selectedIndices: ancestorsOf(homeDir).map(() => 0)
    property int activeColumn: 0
    property bool showHiddenFiles: false
    property bool showSidebar: true
    property bool showPreview: true

    signal settingsRequested
    // DANKFILES_VIEW=list|grid|columns picks the starting view, so a single view
    // can be iterated on without clicking through the switcher every launch.
    property string viewMode: ["columns", "list", "grid"].includes(Quickshell.env("DANKFILES_VIEW")) ? Quickshell.env("DANKFILES_VIEW") : "columns"
    property string sortBy: "name"
    property bool sortAscending: true

    readonly property bool columnsMode: viewMode === "columns"

    readonly property string currentDir: columns[activeColumn] ?? homeDir
    readonly property var activeEntry: entryAt(activeColumn, selectedIndices[activeColumn] ?? 0)
    readonly property string selectedPath: activeEntry ? activeEntry.path : currentDir

    // What "here" means for actions that take a directory. Highlighting a folder
    // opens its column and puts it at the end of the breadcrumb, so that folder
    // is the path on screen - not the column the highlight sits in.
    readonly property string targetDir: activeEntry && activeEntry.isDir ? activeEntry.path : currentDir
    readonly property string windowTitle: displayName(targetDir)
    readonly property string windowSubtitle: displayPath(targetDir)

    // TODO(prototype): tabs, multi-select, the icon grid, the git block in the
    // preview pane, REPOSITORIES/DEVICES sidebar sections and the Ctrl+K overlay
    // are all still stubs. See README.md.

    function encodeFileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split("/").map(s => encodeURIComponent(s)).join("/");
    }

    function baseName(path) {
        if (!path || path === "/")
            return "";
        return path.split("/").filter(s => s.length > 0).pop() ?? "";
    }

    // Every directory from the chain's anchor down to `path`.
    //
    // The anchor is home for anything inside it, and "/" otherwise. Rooting
    // everything at "/" spends two of the three columns on "/" and "/home", and
    // makes the breadcrumb read as an absolute path - selecting a file in ~ gave
    // "/ › home › kmf › test.png" rather than "~ › test.png". Above home is
    // still reachable: going up from the first column prepends its parent.
    function anchorFor(path) {
        // The trash anchors on itself: nobody wants to navigate - or read -
        // ".local › share › Trash › files" to get to it.
        if (trash.isInTrash(path))
            return trash.filesDir;
        return path === homeDir || path.startsWith(homeDir + "/") ? homeDir : "/";
    }

    function ancestorsOf(path) {
        const anchor = anchorFor(path);
        const out = [anchor];
        let walked = anchor === "/" ? "" : anchor;

        for (const segment of path.slice(anchor === "/" ? 0 : anchor.length).split("/")) {
            if (!segment)
                continue;
            walked += "/" + segment;
            out.push(walked);
        }
        return out;
    }

    // "~" for home, "Trash" for the trash's storage directory, "/" for the root,
    // the folder name otherwise. Nobody wants to read
    // ".local › share › Trash › files" as a breadcrumb.
    function displayName(path) {
        if (path === homeDir)
            return "~";
        if (path === trash.filesDir)
            return I18n.tr("Trash");
        return baseName(path) || "/";
    }

    function parentOf(path) {
        return path.replace(/\/[^/]+\/?$/, "") || "/";
    }

    function displayPath(path) {
        if (!path)
            return "";
        if (trash.isInTrash(path))
            return I18n.tr("Trash") + path.slice(trash.filesDir.length);
        return path === homeDir ? "~" : path.startsWith(homeDir + "/") ? "~" + path.slice(homeDir.length) : path;
    }

    // Models are cached per directory rather than instantiated from `columns`.
    // A list-backed Instantiator rebuilds every delegate when the array changes,
    // which put freshly-rebuilt models back into Loading on every keypress and
    // collapsed the chain. Caching also makes revisiting a directory instant.
    // TODO(prototype): evict entries that leave the chain, and watch dirs for
    // external changes.
    property var modelCache: ({})
    property int modelCacheVersion: 0

    function ensureModels() {
        let added = false;
        for (const path of columns) {
            if (!modelCache[path]) {
                modelCache[path] = folderModelComponent.createObject(root, {
                    "folder": encodeFileUrl(path)
                });
                added = true;
            }
        }
        if (added)
            modelCacheVersion++;
    }

    // The column browser's breadcrumb is the chain itself; the flat views have
    // no chain, so their crumbs come from the path.
    function crumbsFor(path) {
        return ancestorsOf(path).map(step => ({
            "label": displayName(step),
            "path": step
        }));
    }

    function modelAt(index) {
        modelCacheVersion; // dependency, so bindings refresh as models appear
        const path = columns[index];
        return path ? modelCache[path] ?? null : null;
    }

    function entryAt(column, index) {
        const model = modelAt(column);
        if (!model || model.status !== FolderListModel.Ready || index < 0 || index >= model.count)
            return null;

        return {
            "name": model.get(index, "fileName"),
            "path": model.get(index, "filePath"),
            "isDir": model.get(index, "fileIsDir"),
            "size": model.get(index, "fileSize"),
            "modified": model.get(index, "fileModified")
        };
    }

    function countAt(column) {
        const model = modelAt(column);
        return model && model.status === FolderListModel.Ready ? model.count : 0;
    }

    // Re-derives the chain below `column` from its selection. Only the column
    // browser wants a child column for the highlighted directory; the flat views
    // would just be reading directories nobody is looking at.
    function syncChain(column) {
        const entry = entryAt(column, selectedIndices[column] ?? 0);
        const child = columnsMode && entry && entry.isDir ? entry.path : null;

        // Unchanged highlight: leave the chain alone. Rebuilding it here would
        // drop the grandchildren every time focus merely moved left.
        if (child && columns[column + 1] === child)
            return;
        if (!child && columns.length === column + 1)
            return;

        const kept = columns.slice(0, column + 1);
        const indices = selectedIndices.slice(0, column + 1);
        if (child) {
            kept.push(child);
            indices.push(0);
        }

        // Reassigning an identical chain would rebuild every FolderListModel,
        // whose status change calls back into here - guard against the loop.
        if (kept.join("\u0000") !== columns.join("\u0000"))
            columns = kept;
        if (indices.join(",") !== selectedIndices.join(","))
            selectedIndices = indices;
        if (activeColumn > columns.length - 1)
            activeColumn = columns.length - 1;
    }

    function select(column, index) {
        clearMultiSelection();
        const bounded = Math.max(0, Math.min(index, countAt(column) - 1));
        if (selectedIndices[column] !== bounded) {
            const next = selectedIndices.slice();
            next[column] = bounded;
            selectedIndices = next;
        }
        activeColumn = column;
        syncChain(column);
    }

    function sortByField(field) {
        if (sortBy === field)
            sortAscending = !sortAscending;
        else {
            sortBy = field;
            sortAscending = true;
        }
    }

    // Multi-selection, as indices within the active column.
    //
    // Indices rather than paths because the status bar needs sizes, which come
    // from the model by index - and it is cleared whenever the column or its
    // sort changes, so a stale index can never be acted on. Empty means "just
    // the cursor", which keeps every single-selection path unchanged.
    property var multiSelection: []

    readonly property var selectedEntries: {
        if (multiSelection.length === 0)
            return activeEntry ? [activeEntry] : [];
        return multiSelection.map(index => entryAt(activeColumn, index)).filter(Boolean);
    }
    readonly property int selectionCount: selectedEntries.length
    readonly property real selectionBytes: selectedEntries.reduce((total, entry) => total + (entry.isDir ? 0 : entry.size), 0)

    onActiveColumnChanged: clearMultiSelection()
    onSortByChanged: clearMultiSelection()
    onSortAscendingChanged: clearMultiSelection()

    function clearMultiSelection() {
        if (multiSelection.length > 0)
            multiSelection = [];
    }

    function isIndexSelected(column, index) {
        if (column !== activeColumn)
            return false;
        if (multiSelection.length === 0)
            return index === (selectedIndices[column] ?? -1);
        return multiSelection.indexOf(index) !== -1;
    }

    // Ctrl-click: add or remove one row, keeping the cursor where the user last
    // put it.
    function toggleSelection(column, index) {
        if (column !== activeColumn)
            select(column, index);

        const current = multiSelection.length === 0 ? [selectedIndices[activeColumn] ?? index] : multiSelection.slice();
        const at = current.indexOf(index);
        if (at === -1)
            current.push(index);
        else if (current.length > 1)
            current.splice(at, 1);

        multiSelection = current;
        selectCursor(index);
    }

    // Shift-click: everything between the cursor and the clicked row.
    function extendSelection(column, index) {
        if (column !== activeColumn)
            select(column, index);

        const from = selectedIndices[activeColumn] ?? index;
        const range = [];
        for (var i = Math.min(from, index); i <= Math.max(from, index); i++)
            range.push(i);

        multiSelection = range;
        selectCursor(index);
    }

    function selectAll() {
        const all = [];
        for (var i = 0; i < countAt(activeColumn); i++)
            all.push(i);
        multiSelection = all;
    }

    // Moves the cursor without touching the multi-selection - select() clears it.
    function selectCursor(index) {
        const bounded = Math.max(0, Math.min(index, countAt(activeColumn) - 1));
        if (selectedIndices[activeColumn] === bounded)
            return;
        const next = selectedIndices.slice();
        next[activeColumn] = bounded;
        selectedIndices = next;
    }

    // The shared FileBrowser delegates expose itemClicked but no doubleClicked,
    // so the flat views detect a double click from two clicks on the same row.
    // Adding doubleClicked to those delegates upstream would replace this.
    property int lastClickIndex: -1
    property double lastClickAt: 0
    readonly property int doubleClickMs: 400

    function clickEntry(index, modifiers) {
        if (modifiers & Qt.ControlModifier) {
            toggleSelection(activeColumn, index);
            takeFocus();
            return;
        }
        if (modifiers & Qt.ShiftModifier) {
            extendSelection(activeColumn, index);
            takeFocus();
            return;
        }

        const now = Date.now();
        const isDouble = index === lastClickIndex && now - lastClickAt < doubleClickMs;
        lastClickIndex = index;
        lastClickAt = now;

        select(activeColumn, index);
        if (isDouble)
            activate();
        takeFocus();
    }

    function moveSelection(delta) {
        select(activeColumn, (selectedIndices[activeColumn] ?? 0) + delta);
    }

    function descend() {
        if (!columnsMode) {
            const entry = activeEntry;
            if (entry && entry.isDir)
                navigateTo(entry.path);
            return;
        }

        if (activeColumn < columns.length - 1) {
            activeColumn = activeColumn + 1;
            syncChain(activeColumn);
        }
    }

    function ascend() {
        if (!columnsMode) {
            navigateUp();
            return;
        }

        if (activeColumn > 0) {
            activeColumn = activeColumn - 1;
            return;
        }

        // At the anchor: step above it, keeping the column we came from
        // highlighted. This is how "/" stays reachable from a home-anchored
        // chain.
        const from = columns[0];
        const above = parentOf(from);
        if (above === from)
            return;

        columns = [above].concat(columns);
        selectedIndices = [0].concat(selectedIndices);
        ensureModels();
        reveal(above, from);
    }

    // Up is a focus move in the column browser and a re-root in the flat views,
    // which keep the directory we came from highlighted so up-then-down lands
    // where you started.
    function navigateUp() {
        if (columnsMode) {
            ascend();
            return;
        }

        const from = currentDir;
        const above = parentOf(from);
        if (above === from)
            return;

        navigateTo(above);
        reveal(above, from);
    }

    // Rebuilds the chain around `path` and highlights each child in its parent,
    // so opening a deep directory shows the way in rather than a bare column.
    function navigateTo(path) {
        if (!path)
            return;

        if (!columnsMode) {
            columns = [path];
            selectedIndices = [0];
            activeColumn = 0;
            ensureModels();
            return;
        }

        const chain = ancestorsOf(path);
        columns = chain;
        selectedIndices = chain.map(() => 0);
        activeColumn = chain.length - 1;
        for (var i = 0; i < chain.length - 1; i++)
            reveal(chain[i], chain[i + 1]);
        ensureModels();
    }

    // Opens the user's terminal in the active directory. The lookup lives in the
    // script rather than in a detection pass here: $TERMINAL first, then the
    // common emulators.
    //
    // `cd` alone is not enough. Several emulators are single-instance: the
    // command hands off to a running daemon and the new window inherits the
    // daemon's directory, not ours. Ghostty ignores both the cd and
    // --working-directory in that mode, and only its +new-window action carries
    // the directory across the IPC hop - with a plain launch as the fallback for
    // when no instance is running. Each other known emulator gets its own
    // working-directory flag, and the cd covers anything not in the list.
    readonly property string terminalScript: [
        'dir="$1"',
        'cd "$dir" || exit 1',
        'for candidate in "$TERMINAL" ghostty kitty alacritty foot wezterm gnome-terminal konsole xterm; do',
        '    [ -n "$candidate" ] || continue',
        '    command -v "$candidate" >/dev/null 2>&1 || continue',
        '    case "$(basename "$candidate")" in',
        '        ghostty) "$candidate" +new-window --working-directory="$dir" && exit 0; exec "$candidate" --working-directory="$dir" ;;',
        '        foot|alacritty|gnome-terminal) exec "$candidate" --working-directory="$dir" ;;',
        '        kitty) exec "$candidate" --directory "$dir" ;;',
        '        wezterm) exec "$candidate" start --cwd "$dir" ;;',
        '        konsole) exec "$candidate" --workdir "$dir" ;;',
        '        *) exec "$candidate" ;;',
        '    esac',
        'done',
        'exit 127'
    ].join("\n")

    property string statusMessage: ""
    readonly property bool inTrash: trash.isInTrash(targetDir)

    // What a confirmed destructive action should run, and the path it will
    // remove - the chain has to be rewritten around it afterwards.
    property var pendingConfirm: (() => {})
    property string pendingTrashPath: ""

    function askDeleteForever(path, name) {
        pendingTrashPath = path;
        pendingConfirm = () => trash.deleteForever(path);
        confirmDialog.ask(I18n.tr("Delete permanently"), I18n.tr("%1 will be deleted for good. This cannot be undone.").arg(name), I18n.tr("Delete"), "delete_forever");
    }

    function askEmptyTrash() {
        pendingTrashPath = trash.filesDir;
        pendingConfirm = () => trash.empty();
        confirmDialog.ask(I18n.tr("Empty Trash"), I18n.tr("Everything in the trash will be deleted for good. This cannot be undone."), I18n.tr("Empty Trash"), "delete_sweep");
    }

    function restoreFromTrash(path) {
        pendingTrashPath = path;
        trash.restore(path);
    }

    // Ctrl+Z reads as undo, so it restores the selected item when browsing the
    // trash and otherwise puts back the last thing this session trashed.
    property string lastTrashedPath: ""

    // Trashing several things is several operations; the chain is rewritten once
    // per removal, and the last one wins the status message.
    function trashSelection() {
        const entries = selectedEntries;
        for (const entry of entries)
            fileOps.trash(entry.path);
        clearMultiSelection();
        if (entries.length > 1)
            report(I18n.tr("Moved %1 items to trash").arg(entries.length));
    }

    function copySelectionPaths() {
        const paths = selectedEntries.map(entry => entry.path);
        if (paths.length === 0)
            return;
        Paths.copyPathToClipboard(paths.join("\n"));
        report(paths.length > 1 ? I18n.tr("Copied %1 paths").arg(paths.length) : I18n.tr("Copied %1").arg(paths[0]));
    }

    // Internal clipboard for copy/cut/paste. Paths, not indices: the selection
    // is cleared on navigation, but the clipboard has to survive it.
    property var clipPaths: []
    property bool clipCut: false
    readonly property bool canPaste: clipPaths.length > 0 && !inTrash

    function copySelection() {
        const paths = selectedEntries.map(entry => entry.path);
        if (paths.length === 0)
            return;
        clipPaths = paths;
        clipCut = false;
        Paths.copyPathToClipboard(paths.join("\n"));
        report(paths.length > 1 ? I18n.tr("Copied %1 items").arg(paths.length) : I18n.tr("Copied %1").arg(baseName(paths[0])));
    }

    function cutSelection() {
        if (inTrash)
            return;
        const paths = selectedEntries.map(entry => entry.path);
        if (paths.length === 0)
            return;
        clipPaths = paths;
        clipCut = true;
        Paths.copyPathToClipboard(paths.join("\n"));
        report(paths.length > 1 ? I18n.tr("Cut %1 items").arg(paths.length) : I18n.tr("Cut %1").arg(baseName(paths[0])));
    }

    function pasteClipboard(dest) {
        if (clipPaths.length === 0) {
            report(I18n.tr("Nothing to paste"));
            return;
        }
        const directory = dest || currentDir;
        if (trash.isInTrash(directory)) {
            report(I18n.tr("Can't paste into the trash"));
            return;
        }
        fileOps.transfer(clipPaths, directory, clipCut);
    }

    function undoTrash() {
        if (inTrash && activeEntry) {
            restoreFromTrash(activeEntry.path);
            return;
        }
        if (!lastTrashedPath) {
            report(I18n.tr("Nothing to undo"));
            return;
        }

        const original = lastTrashedPath;
        lastTrashedPath = "";
        trash.restoreOriginal(original);
    }

    function report(message) {
        statusMessage = message;
        statusMessageTimer.restart();
    }

    // FolderListModel does not re-read on its own, so a write has to push the
    // directory it touched back through the model.
    function refreshDir(directory) {
        const model = modelCache[directory];
        if (!model)
            return;
        model.folder = "";
        model.folder = encodeFileUrl(directory);
    }

    // Reveals whatever the user typed: a directory opens, a file opens its
    // parent with the file highlighted, and anything else is reported rather
    // than silently ignored. The kind has to be probed - QML has no stat.
    function revealPath(input) {
        const path = input.startsWith("~") ? homeDir + input.slice(1) : input;
        if (!path.startsWith("/")) {
            report(I18n.tr("Not an absolute path: %1").arg(input));
            return;
        }

        const trimmed = path.length > 1 ? path.replace(/\/$/, "") : path;
        Proc.runCommand(null, host.wrap(["sh", "-c", 'if [ -d "$1" ]; then echo dir; elif [ -e "$1" ]; then echo file; else echo none; fi', "sh", trimmed]), output => {
            switch (output.trim()) {
            case "dir":
                root.navigateTo(trimmed);
                break;
            case "file":
                root.navigateTo(root.parentOf(trimmed));
                root.reveal(root.parentOf(trimmed), trimmed);
                break;
            default:
                root.report(I18n.tr("No such path: %1").arg(input));
                break;
            }
            root.takeFocus();
        }, 0, 5000, root);
    }

    // A rename or a trash can move the ground out from under the column chain:
    // the columns still name the old path, the model behind them is empty, and
    // because nothing is selectable there every keybinding silently does
    // nothing. Rewrite affected columns to the new path, or drop them.
    function rewriteChain(oldPath, newPath) {
        const affected = columns.findIndex(path => path === oldPath || path.startsWith(oldPath + "/"));
        if (affected === -1)
            return;

        delete modelCache[oldPath];

        if (!newPath) {
            columns = columns.slice(0, affected);
            selectedIndices = selectedIndices.slice(0, affected);
        } else {
            columns = columns.map(path => path === oldPath ? newPath : path.startsWith(oldPath + "/") ? newPath + path.slice(oldPath.length) : path);
        }

        if (columns.length === 0) {
            navigateTo(parentOf(oldPath));
            return;
        }

        if (activeColumn > columns.length - 1)
            activeColumn = columns.length - 1;
        ensureModels();
        takeFocus();
    }

    function openContextMenu(parentItem, localX, localY, path, name, isDir, directoryMenu) {
        if (!parentItem)
            return;
        // Parent the popup to this surface, not the clipped ListView that
        // called us: that view is destroyed on navigate, which is when paste
        // is the next thing the user tries, and clip: true would hide the menu.
        const point = parentItem.mapToItem(root, localX, localY);
        contextMenu.bookmarked = bookmarks.has(path);
        contextMenu.trashMode = trash.isInTrash(path);
        contextMenu.canPaste = root.canPaste;
        contextMenu.directoryMenu = directoryMenu === true;
        contextMenu.showAt(root, point.x, point.y, path, name, isDir);
    }

    function openTerminalIn(directory) {
        Quickshell.execDetached(host.wrap(["sh", "-c", terminalScript, "sh", directory]));
    }

    function openTerminal() {
        openTerminalIn(targetDir);
    }

    // One prompt serves rename, new folder and a custom open-with command, so it
    // needs to remember which question it is currently asking.
    property string pendingAction: ""
    property string pendingPath: ""

    function askRename(path, name) {
        pendingAction = "rename";
        pendingPath = path;
        nameDialog.ask(I18n.tr("Rename"), displayPath(path), name);
    }

    function askNewFolder(directory) {
        pendingAction = "newFolder";
        pendingPath = directory;
        nameDialog.ask(I18n.tr("New folder"), displayPath(directory), I18n.tr("untitled folder"), {
            "iconName": "create_new_folder"
        });
    }

    function askCommand(path) {
        pendingAction = "command";
        pendingPath = path;
        nameDialog.ask(I18n.tr("Open with"), displayPath(path), "", {
            "allowSlashes": true,
            "fieldLabel": I18n.tr("Command"),
            "iconName": "terminal"
        });
    }

    function askOpenWith(path, name) {
        openWith.load(path);
        openWithDialog.show(name);
    }

    function showDiff() {
        gitStatus.loadDiff();
        diffDialog.opened = true;
    }

    function activate() {
        const entry = activeEntry;
        if (!entry)
            return;

        if (entry.isDir)
            descend();
        else
            openProcess.startDetached(entry.path);
    }

    // Directory -> the child path that should end up highlighted in it, applied
    // once that directory's model is Ready. Keyed by path rather than by column
    // index so a chain that shifts underneath a pending reveal still resolves.
    // FolderListModel populates asynchronously, so this is the only way to
    // select something by name.
    property var revealTargets: ({})

    // `enter` moves focus into the revealed entry when it turns out to be a
    // directory, so "show me this path" lands inside a folder but on a file.
    function reveal(directory, target, enter) {
        revealTargets[directory] = {
            "target": target,
            "enter": enter === true
        };
        tryReveal();
    }

    function tryReveal() {
        let resolved = false;

        let enterColumn = -1;

        for (var column = 0; column < columns.length; column++) {
            const directory = columns[column];
            const request = revealTargets[directory];
            if (!request)
                continue;

            const model = modelAt(column);
            if (!model || model.status !== FolderListModel.Ready)
                continue;

            for (var i = 0; i < model.count; i++) {
                if (model.get(i, "filePath") === request.target) {
                    if (selectedIndices[column] !== i) {
                        const next = selectedIndices.slice();
                        next[column] = i;
                        selectedIndices = next;
                    }
                    if (request.enter && model.get(i, "fileIsDir"))
                        enterColumn = column + 1;
                    resolved = true;
                    break;
                }
            }
            delete revealTargets[directory];
        }

        if (!resolved)
            return;

        syncChain(activeColumn);
        if (enterColumn > 0 && enterColumn < columns.length)
            activeColumn = enterColumn;
    }

    focus: true
    activeFocusOnTab: true

    // forceActiveFocus() on a FocusScope restores focus to whichever child last
    // held it - after using the path field that is a hidden text input, which
    // then swallows every keystroke silently. Focusing a dedicated anchor makes
    // "give the keyboard back to the browser" unambiguous.
    Item {
        id: keyboardAnchor

        focus: true
    }

    function takeFocus() {
        keyboardAnchor.forceActiveFocus();
    }

    // DANKFILES_PATH=<path> starts with that file or directory revealed, so a
    // specific case can be reproduced without navigating to it every launch.
    Component.onCompleted: {
        const start = Quickshell.env("DANKFILES_PATH");
        if (start && start.startsWith("/")) {
            const target = start.replace(/\/$/, "");
            navigateTo(parentOf(target));
            reveal(parentOf(target), target, true);
        } else {
            navigateTo(homeDir);
        }
        ensureModels();
        takeFocus();
    }

    onColumnsChanged: ensureModels()

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_A:
            if (event.modifiers & Qt.ControlModifier)
                selectAll();
            else
                return;
            break;
        case Qt.Key_Escape:
            // Swallow it either way: unhandled, it propagates to the window and
            // closes the app.
            if (multiSelection.length > 0)
                clearMultiSelection();
            else if (confirmDialog.opened)
                confirmDialog.opened = false;
            else if (diffDialog.opened)
                diffDialog.opened = false;
            else if (openWithDialog.opened)
                openWithDialog.opened = false;
            else if (nameDialog.opened)
                nameDialog.opened = false;
            else
                break;
            takeFocus();
            break;
        case Qt.Key_BracketLeft:
            showSidebar = !showSidebar;
            break;
        case Qt.Key_BracketRight:
            showPreview = !showPreview;
            break;
        case Qt.Key_L:
            if (event.modifiers & Qt.ControlModifier)
                toolbar.beginPathEdit();
            else
                return;
            break;
        case Qt.Key_F2:
            if (activeEntry)
                askRename(activeEntry.path, activeEntry.name);
            break;
        case Qt.Key_Z:
            if (event.modifiers & Qt.ControlModifier)
                undoTrash();
            else
                return;
            break;
        case Qt.Key_Delete:
            if (!activeEntry)
                break;
            if (inTrash)
                askDeleteForever(activeEntry.path, activeEntry.name);
            else
                trashSelection();
            break;
        case Qt.Key_N:
            if (event.modifiers & Qt.ControlModifier)
                askNewFolder(targetDir);
            else
                return;
            break;
        case Qt.Key_T:
            openTerminal();
            break;
        case Qt.Key_B:
            bookmarks.toggle(targetDir);
            break;
        case Qt.Key_S:
            if (gitStatus.dirty)
                gitStatus.staged ? gitStatus.unstage() : gitStatus.stage();
            break;
        case Qt.Key_D:
            if (gitStatus.dirty)
                showDiff();
            break;
        case Qt.Key_Down:
            if (event.modifiers & Qt.ShiftModifier)
                extendSelection(activeColumn, (selectedIndices[activeColumn] ?? 0) + 1);
            else
                moveSelection(1);
            break;
        case Qt.Key_Up:
            if (event.modifiers & Qt.ShiftModifier)
                extendSelection(activeColumn, (selectedIndices[activeColumn] ?? 0) - 1);
            else
                moveSelection(-1);
            break;
        case Qt.Key_Right:
            descend();
            break;
        case Qt.Key_Left:
            ascend();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            activate();
            break;
        case Qt.Key_Home:
            select(activeColumn, 0);
            break;
        case Qt.Key_End:
            select(activeColumn, countAt(activeColumn) - 1);
            break;
        case Qt.Key_Period:
            if (event.modifiers & Qt.ControlModifier)
                showHiddenFiles = !showHiddenFiles;
            else
                return;
            break;
        default:
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Shortcut {
        sequences: [StandardKey.Copy]
        enabled: !toolbar.pathEditMode && !nameDialog.opened
        onActivated: root.copySelection()
    }

    Shortcut {
        sequences: [StandardKey.Cut]
        enabled: !toolbar.pathEditMode && !nameDialog.opened && !root.inTrash
        onActivated: root.cutSelection()
    }

    Shortcut {
        sequences: [StandardKey.Paste]
        enabled: !toolbar.pathEditMode && !nameDialog.opened
        onActivated: root.pasteClipboard()
    }

    Shortcut {
        sequence: "Ctrl+,"
        enabled: !toolbar.pathEditMode && !nameDialog.opened
        onActivated: root.settingsRequested()
    }

    // Opt-in smoke test for the navigation model - see NavigationSelfTest.qml.
    Loader {
        active: Quickshell.env("DANKFILES_SELFTEST") === "1"
        source: "NavigationSelfTest.qml"
        onLoaded: item.target = root
    }

    Component {
        id: folderModelComponent

        FolderListModel {
            showDirsFirst: true
            showDotAndDotDot: false
            showHidden: root.showHiddenFiles
            caseSensitive: false
            // FolderListModel's sortReversed is not consistent across fields:
            // with Name, false means A-Z, but with Size and Time false means
            // largest/newest first. Verified against Qt 6 / Quickshell 0.3.1 by
            // reading back the model for every field/flag combination.
            sortReversed: root.sortBy === "size" || root.sortBy === "modified" ? root.sortAscending : !root.sortAscending
            sortField: {
                switch (root.sortBy) {
                case "size":
                    return FolderListModel.Size;
                case "modified":
                    return FolderListModel.Time;
                case "type":
                    return FolderListModel.Type;
                default:
                    return FolderListModel.Name;
                }
            }
            onStatusChanged: {
                if (status !== FolderListModel.Ready)
                    return;
                root.modelCacheVersion++;
                root.tryReveal();
                root.syncChain(root.activeColumn);
            }
        }
    }







    HostCommands {
        id: host
    }

    BookmarksService {
        id: bookmarks
    }









    TrashService {
        id: trash

        host: host

        path: root.selectedPath
        onChanged: {
            root.refreshDir(root.trash.filesDir);
            if (root.trash.restoredTo) {
                root.refreshDir(root.parentOf(root.trash.restoredTo));
                root.report(I18n.tr("Restored to %1").arg(root.displayPath(root.trash.restoredTo)));
                root.trash.restoredTo = "";
            }
            root.rewriteChain(root.pendingTrashPath, "");
            root.pendingTrashPath = "";
        }
        onFailed: message => root.report(message)
    }

    FmConfirmDialog {
        id: confirmDialog

        anchors.fill: parent
        z: 100
        onRejected: {
            opened = false;
            root.takeFocus();
        }
        onConfirmed: {
            root.pendingConfirm();
            root.takeFocus();
        }
    }

    FileOps {
        id: fileOps

        host: host

        onChanged: directory => {
            root.refreshDir(directory);
            gitStatus.refresh();
        }
        onTrashed: originalPath => root.lastTrashedPath = originalPath
        onRenamed: (oldPath, newPath) => root.rewriteChain(oldPath, newPath)
        onRemoved: path => root.rewriteChain(path, "")
        onTransferred: (count, cut, ok) => {
            if (cut && ok) {
                root.clipPaths = [];
                root.clipCut = false;
            }
            if (count <= 0)
                return;
            if (cut)
                root.report(count === 1 ? I18n.tr("Moved 1 item") : I18n.tr("Moved %1 items").arg(count));
            else
                root.report(count === 1 ? I18n.tr("Pasted 1 item") : I18n.tr("Pasted %1 items").arg(count));
        }
        onFailed: message => root.report(message)
    }

    Timer {
        id: statusMessageTimer

        interval: 5000
        onTriggered: root.statusMessage = ""
    }

    GitService {
        id: gitStatus

        host: host

        path: root.selectedPath
    }

    Process {
        id: openProcess

        function startDetached(path) {
            command = host.wrap(["xdg-open", path]);
            running = true;
        }
    }

    FmContextMenu {
        id: contextMenu

        onClosed: Qt.callLater(root.takeFocus)
        onOpenRequested: {
            if (fileIsDir)
                root.navigateTo(filePath);
            else
                openProcess.startDetached(filePath);
        }
        onOpenWithRequested: root.askOpenWith(filePath, fileName)
        onTerminalRequested: root.openTerminalIn(fileIsDir ? filePath : fileOps.parentOf(filePath))
        onCopyRequested: root.copySelection()
        onCutRequested: root.cutSelection()
        onPasteRequested: root.pasteClipboard(contextMenu.directoryMenu ? contextMenu.filePath : root.currentDir)
        onCopyPathRequested: root.copySelectionPaths()
        onBookmarkRequested: bookmarks.toggle(filePath)
        onRenameRequested: root.askRename(filePath, fileName)
        onNewFolderRequested: root.askNewFolder(fileIsDir ? filePath : fileOps.parentOf(filePath))
        onTrashRequested: root.trashSelection()
        onRestoreRequested: root.restoreFromTrash(filePath)
        onDeleteForeverRequested: root.askDeleteForever(filePath, fileName)
        onEmptyTrashRequested: root.askEmptyTrash()
    }





    OpenWithService {
        id: openWith

        host: host

        onFailed: message => root.report(message)
    }

    FmOpenWithDialog {
        id: openWithDialog

        anchors.fill: parent
        z: 100
        service: openWith
        onChosen: (appId, makeDefault) => {
            if (makeDefault)
                openWith.setDefault(appId);
            openWith.launch(appId, openWith.path);
            root.takeFocus();
        }
        onCustomRequested: root.askCommand(openWith.path)
        onRejected: root.takeFocus()
    }

    FmNameDialog {
        id: nameDialog

        anchors.fill: parent
        z: 100
        onSubmitted: value => {
            switch (root.pendingAction) {
            case "rename":
                fileOps.rename(root.pendingPath, value);
                break;
            case "newFolder":
                fileOps.createFolder(root.pendingPath, value);
                break;
            case "command":
                openWith.launchCommand(value, root.pendingPath);
                break;
            }
            root.pendingAction = "";
            root.takeFocus();
        }
        onRejected: root.takeFocus()
    }

    GitDiffDialog {
        id: diffDialog

        anchors.fill: parent
        z: 100
        git: gitStatus
        fileName: root.activeEntry ? root.activeEntry.name : ""
        opened: false
        onRejected: {
            opened = false;
            root.takeFocus();
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.surface

        Row {
            anchors.fill: parent
            spacing: 0

            FmSidebar {
                id: sidebar

                visible: root.showSidebar
                width: visible ? 201 : 0
                height: parent.height
                currentPath: root.currentDir
                bookmarks: bookmarks.paths
                trashPath: trash.filesDir
                onLocationSelected: path => {
                    root.navigateTo(path);
                    root.takeFocus();
                }
                onBookmarkRemoved: path => {
                    bookmarks.remove(path);
                    root.takeFocus();
                }
                onEmptyTrashRequested: root.askEmptyTrash()
            }

            Column {
                width: parent.width - sidebar.width
                height: parent.height
                spacing: 0

                FmToolbar {
                    id: toolbar

                    width: parent.width
                    crumbs: root.columnsMode ? root.columns.map(path => ({
                                "label": root.displayName(path),
                                "path": path
                            })) : root.crumbsFor(root.currentDir)
                    trailingCrumb: root.activeEntry && !root.activeEntry.isDir ? root.activeEntry.name : ""
                    viewMode: root.viewMode
                    canGoUp: root.columnsMode ? root.activeColumn > 0 : root.currentDir !== "/"
                    sidebarShown: root.showSidebar
                    previewShown: root.showPreview
                    onSidebarToggled: {
                        root.showSidebar = !root.showSidebar;
                        root.takeFocus();
                    }
                    onPreviewToggled: {
                        root.showPreview = !root.showPreview;
                        root.takeFocus();
                    }
                    bookmarked: bookmarks.has(root.targetDir)
                    editablePath: root.targetDir
                    onPathSubmitted: path => root.revealPath(path)
                    onPathEditFinished: root.takeFocus()
                    onTerminalRequested: {
                        root.openTerminal();
                        root.takeFocus();
                    }
                    onBookmarkToggled: {
                        bookmarks.toggle(root.targetDir);
                        root.takeFocus();
                    }
                    onCrumbActivated: path => {
                        root.navigateTo(path);
                        root.takeFocus();
                    }
                    onUpRequested: {
                        root.navigateUp();
                        root.takeFocus();
                    }
                    onViewModeRequested: mode => {
                        root.viewMode = mode;
                        root.syncChain(root.activeColumn);
                        root.takeFocus();
                    }
                    onSettingsRequested: root.settingsRequested()
                }

                Item {
                    id: viewArea

                    width: parent.width
                    height: parent.height - toolbar.height - statusBar.height

                    Row {
                        anchors.fill: parent
                        visible: root.viewMode === "columns"
                        spacing: 0

                        MillerView {
                            id: millerView

                            width: parent.width - preview.width
                            height: parent.height
                            owner: root
                        }

                        PreviewPane {
                            id: preview

                            // The columns are the point of this view; on a narrow
                            // window the preview gives up its space to them even
                            // when it is switched on.
                            visible: root.showPreview && viewArea.width >= Style.mediumBreakpoint + 328
                            width: visible ? 328 : 0
                            height: parent.height
                            entry: root.activeEntry
                            trash: trash
                            inTrash: root.inTrash
                            git: gitStatus
                            onDiffRequested: root.showDiff()
                        }
                    }

                    FmListView {
                        anchors.fill: parent
                        visible: root.viewMode === "list"
                        owner: root
                    }

                    FmGridView {
                        anchors.fill: parent
                        visible: root.viewMode === "grid"
                        owner: root
                    }
                }

                FmStatusBar {
                    id: statusBar

                    width: parent.width
                    pathLabel: root.displayPath(root.currentDir)
                    message: root.statusMessage
                    itemCount: root.countAt(root.activeColumn)
                    selectionLabel: root.multiSelection.length > 1 ? I18n.tr("%1 selected").arg(root.selectionCount) + " · " + FileIcons.formatSize(root.selectionBytes) : root.activeEntry ? root.activeEntry.name : ""
                    hiddenFiles: root.showHiddenFiles
                    onToggleHidden: {
                        root.showHiddenFiles = !root.showHiddenFiles;
                        root.takeFocus();
                    }
                }
            }
        }
    }
}
