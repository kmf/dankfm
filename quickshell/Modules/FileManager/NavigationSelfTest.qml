import QtQuick

// Drives the navigation model without a compositor in the loop, so the column
// chain and sorting can be checked from a plain run:
//
//   DANKFILES_SELFTEST=1 qs -p . 2>&1 | grep SELFTEST
//   DANKFILES_VIEW=list DANKFILES_SELFTEST=1 qs -p . 2>&1 | grep SELFTEST
//
// Steps are spaced out because FolderListModel loads and re-sorts
// asynchronously - reading it back in the same tick returns the previous order.
// Keyboard input itself still needs a human; this only covers the state machine
// behind it.
QtObject {
    id: root

    property var target: null
    property int step: 0

    function tail(fm) {
        const last = fm.countAt(fm.activeColumn) - 1;
        return fm.entryAt(fm.activeColumn, last - 1)?.name + " | " + fm.entryAt(fm.activeColumn, last)?.name;
    }

    property Timer runner: Timer {
        running: root.target !== null
        interval: 600
        repeat: true

        onTriggered: {
            const fm = root.target;

            switch (root.step++) {
            case 0:
                console.log("SELFTEST start  ", fm.currentDir, fm.selectedPath);
                fm.sortByField("size");
                break;
            case 1:
                console.log("SELFTEST sort   ", fm.sortBy, fm.sortAscending ? "asc" : "desc", "tail:", root.tail(fm));
                fm.sortByField("size");
                break;
            case 2:
                console.log("SELFTEST sort   ", fm.sortBy, fm.sortAscending ? "asc" : "desc", "tail:", root.tail(fm));
                fm.sortByField("name");
                break;
            case 3:
                fm.moveSelection(1);
                fm.moveSelection(1);
                console.log("SELFTEST jj     ", fm.selectedPath, "columns:", JSON.stringify(fm.columns));
                fm.descend();
                break;
            case 4:
                console.log("SELFTEST l      ", fm.currentDir, "activeColumn:", fm.activeColumn);
                fm.ascend();
                break;
            case 5:
                console.log("SELFTEST h      ", fm.currentDir, fm.selectedPath, "activeColumn:", fm.activeColumn);
                fm.navigateUp();
                break;
            case 6:
                console.log("SELFTEST up     ", JSON.stringify(fm.columns), fm.selectedPath);
                // Two clicks inside one step land well within the double-click
                // window, which is how the flat views open an entry.
                fm.clickEntry(0);
                fm.clickEntry(0);
                break;
            default:
                console.log("SELFTEST dblclick", fm.currentDir, "activeColumn:", fm.activeColumn);
                running = false;
                break;
            }
        }
    }
}
