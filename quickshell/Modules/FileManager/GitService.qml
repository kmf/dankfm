pragma ComponentBehavior: Bound

import QtQuick
import qs.DankCommon.Common

// Git state for whichever path is selected.
//
// One shell round-trip collects everything the preview block shows, so the
// numbers on screen always describe the same moment - running five separate
// git commands would let the branch, the counts and the file state disagree
// while the user scrolls. Proc debounces by id, so holding j does not spawn a
// process per row.
QtObject {
    id: root

    // Commands run on the host when sandboxed - see HostCommands.
    required property var host

    // File or directory to describe. Directories report their whole subtree,
    // which is what the sidebar's repository rows will want later.
    property string path: ""

    property string repoRoot: ""
    property string branch: ""
    property string head: ""
    property int ahead: 0
    property int behind: 0
    property string statusCode: ""
    property int changedFiles: 0
    property int addedLines: 0
    property int removedLines: 0
    property bool loading: false

    property string diffText: ""
    property bool diffLoading: false

    readonly property bool inRepo: repoRoot.length > 0
    readonly property bool dirty: changedFiles > 0
    readonly property bool untracked: statusCode.trim() === "??"
    readonly property bool staged: !untracked && statusCode.length > 0 && statusCode.charAt(0) !== " "
    readonly property bool unstaged: !untracked && statusCode.length > 1 && statusCode.charAt(1) !== " "

    readonly property string stateLabel: {
        if (!inRepo)
            return "";
        if (untracked)
            return I18n.tr("Untracked");
        if (changedFiles > 1)
            return I18n.tr("%1 files changed").arg(changedFiles);
        if (staged && unstaged)
            return I18n.tr("Staged · more changes");
        if (staged)
            return I18n.tr("Staged");
        if (unstaged)
            return I18n.tr("Modified · not staged");
        return I18n.tr("No local changes");
    }

    readonly property string branchLabel: {
        if (!inRepo)
            return "";
        const parts = [branch || "detached"];
        if (head)
            parts.push(head);
        if (ahead > 0)
            parts.push(I18n.tr("%1 commits ahead").arg(ahead));
        if (behind > 0)
            parts.push(I18n.tr("%1 commits behind").arg(behind));
        return parts.join(" · ");
    }

    // $1 is the directory to resolve the repo from, $2 the path being described.
    // Written as lines so the shell quoting stays readable: every \\t and \\n
    // below reaches printf as an escape, not as a literal tab or newline.
    readonly property string statusScript: [
        'dir="$1"; target="$2"',
        'root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0',
        'porcelain=$(git -C "$root" status --porcelain -- "$target" 2>/dev/null)',
        'printf "root\\t%s\\n" "$root"',
        'printf "branch\\t%s\\n" "$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"',
        'printf "head\\t%s\\n" "$(git -C "$root" rev-parse --short HEAD 2>/dev/null)"',
        'printf "ab\\t%s\\n" "$(git -C "$root" rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)"',
        'printf "status\\t%s\\n" "$(printf "%s" "$porcelain" | head -n1)"',
        'printf "changed\\t%s\\n" "$(printf "%s" "$porcelain" | grep -c .)"',
        'printf "unstaged\\t%s\\n" "$(git -C "$root" diff --numstat -- "$target" 2>/dev/null | awk \'{a+=$1; r+=$2} END {print a+0, r+0}\')"',
        'printf "staged\\t%s\\n" "$(git -C "$root" diff --cached --numstat -- "$target" 2>/dev/null | awk \'{a+=$1; r+=$2} END {print a+0, r+0}\')"'
    ].join("\n")

    function containingDir(target) {
        return target.replace(/\/[^/]+\/?$/, "") || "/";
    }

    function reset() {
        repoRoot = "";
        branch = "";
        head = "";
        ahead = 0;
        behind = 0;
        statusCode = "";
        changedFiles = 0;
        addedLines = 0;
        removedLines = 0;
        diffText = "";
    }

    function refresh() {
        if (!path) {
            reset();
            return;
        }

        loading = true;
        Proc.runCommand("dfm-git-status", host.wrap(["sh", "-c", statusScript, "sh", containingDir(path), path]), (output, exitCode) => {
            loading = false;
            if (exitCode !== 0) {
                reset();
                return;
            }
            root.parseStatus(output);
        }, 120, 5000, root);
    }

    function parseStatus(output) {
        const fields = {};
        for (const line of output.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab > 0)
                fields[line.slice(0, tab)] = line.slice(tab + 1);
        }

        if (!fields["root"]) {
            reset();
            return;
        }

        repoRoot = fields["root"];
        branch = fields["branch"] ?? "";
        head = fields["head"] ?? "";

        // rev-list --left-right --count prints "<behind>\t<ahead>"
        const ab = (fields["ab"] ?? "").split(/\s+/).filter(s => s.length > 0);
        behind = ab.length > 1 ? parseInt(ab[0]) || 0 : 0;
        ahead = ab.length > 1 ? parseInt(ab[1]) || 0 : 0;

        statusCode = (fields["status"] ?? "").slice(0, 2);
        changedFiles = parseInt(fields["changed"] ?? "0") || 0;

        const unstagedNumstat = (fields["unstaged"] ?? "").split(/\s+/);
        const stagedNumstat = (fields["staged"] ?? "").split(/\s+/);
        addedLines = (parseInt(unstagedNumstat[0]) || 0) + (parseInt(stagedNumstat[0]) || 0);
        removedLines = (parseInt(unstagedNumstat[1]) || 0) + (parseInt(stagedNumstat[1]) || 0);

        if (changedFiles > 0)
            Qt.callLater(() => root.loadDiff());
        else
            diffText = "";
    }

    function stage() {
        runWrite(["git", "-C", repoRoot, "add", "--", path]);
    }

    function unstage() {
        runWrite(["git", "-C", repoRoot, "restore", "--staged", "--", path]);
    }

    function runWrite(command) {
        if (!inRepo)
            return;
        Proc.runCommand("dfm-git-write", host.wrap(command), () => root.refresh(), 0, 5000, root);
    }

    function loadDiff() {
        if (!inRepo)
            return;

        diffLoading = true;
        const command = ["sh", "-c", 'git -C "$1" diff HEAD -- "$2" 2>/dev/null | head -n 400', "sh", repoRoot, path];
        Proc.runCommand("dfm-git-diff", host.wrap(command), (output, exitCode) => {
            diffLoading = false;
            diffText = exitCode === 0 ? output : "";
        }, 0, 5000, root);
    }

    onPathChanged: refresh()
}
