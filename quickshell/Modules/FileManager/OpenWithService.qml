pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.DankCommon.Common

// The applications that can open a given file.
//
// Quickshell's DesktopEntries returns nothing in this environment, so the list
// comes from the XDG tools themselves: xdg-mime for the type and the default,
// gio for the recommended handlers, and the .desktop files for names and icons.
QtObject {
    id: root

    // Commands run on the host when sandboxed - see HostCommands.
    required property var host

    property string path: ""
    property string mimeType: ""
    property string defaultId: ""
    property var apps: []
    property bool loading: false

    readonly property string lookupScript: [
        'target="$1"',
        'mime=$(xdg-mime query filetype "$target" 2>/dev/null)',
        '[ -n "$mime" ] || exit 1',
        'printf "mime\\t%s\\n" "$mime"',
        'printf "default\\t%s\\n" "$(xdg-mime query default "$mime" 2>/dev/null)"',
        'dirs=$(printf "%s\\n%s/.local/share\\n%s\\n" "${XDG_DATA_HOME:-}" "$HOME" "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}" | tr ":" "\\n" | grep -v "^$")',
        'gio mime "$mime" 2>/dev/null | sed -n "/Recommended applications:/,\\$p" | sed "1d" | tr -d "\\t " | grep -v "^$" | while read -r id; do',
        '    printf "%s\\n" "$dirs" | while read -r dir; do',
        '        file="$dir/applications/$id"',
        '        [ -f "$file" ] || continue',
        '        name=$(sed -n "s/^Name=//p" "$file" | head -n1)',
        '        icon=$(sed -n "s/^Icon=//p" "$file" | head -n1)',
        '        printf "app\\t%s\\t%s\\t%s\\n" "$id" "${name:-$id}" "$icon"',
        '        break',
        '    done',
        'done'
    ].join("\n")

    // .desktop Icon= is either an icon-theme name or an absolute path.
    function iconSource(icon) {
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        return Quickshell.iconPath(icon, true);
    }

    function load(target) {
        path = target;
        mimeType = "";
        defaultId = "";
        apps = [];
        loading = true;

        Proc.runCommand("dfm-open-with", host.wrap(["sh", "-c", lookupScript, "sh", target]), (output, exitCode) => {
            root.loading = false;
            if (exitCode !== 0)
                return;
            root.parse(output);
        }, 0, 5000, root);
    }

    function parse(output) {
        const found = [];
        const seen = {};

        for (const line of output.split("\n")) {
            const fields = line.split("\t");
            switch (fields[0]) {
            case "mime":
                mimeType = fields[1] ?? "";
                break;
            case "default":
                defaultId = fields[1] ?? "";
                break;
            case "app": {
                if (!fields[1])
                    break;

                // Several programs ship more than one desktop file - Brave and
                // Chrome both do - and listing the same name twice is just
                // confusing. Dedupe on the visible name, but let the default
                // handler win the slot so it keeps its "default" tag.
                const app = {
                    "id": fields[1],
                    "name": fields[2] || fields[1],
                    "icon": fields[3] ?? ""
                };
                const existing = seen[app.name];
                if (existing === undefined) {
                    seen[app.name] = found.length;
                    found.push(app);
                } else if (app.id === defaultId) {
                    found[existing] = app;
                }
                break;
            }
            }
        }

        apps = found;
    }

    function launch(appId, target) {
        Quickshell.execDetached(host.wrap(["gtk-launch", appId, target]));
    }

    // $1 stays unquoted so a command typed with arguments still splits, while
    // the file it is given does not.
    function launchCommand(command, target) {
        if (!command.trim())
            return;
        Quickshell.execDetached(host.wrap(["sh", "-c", 'exec $1 "$2"', "sh", command.trim(), target]));
    }

    function setDefault(appId) {
        if (!appId || !mimeType)
            return;
        Proc.runCommand(null, host.wrap(["xdg-mime", "default", appId, mimeType]), (output, exitCode) => {
            if (exitCode === 0)
                root.defaultId = appId;
            else
                root.failed(I18n.tr("Could not set the default application"));
        }, 0, 5000, root);
    }

    signal failed(string message)
}
