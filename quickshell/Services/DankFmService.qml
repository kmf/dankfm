pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services
import qs.DankCommon.Common

// Bridge to the dfm daemon over DANKFM_SOCKET.
Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("DANKFM_SOCKET") ?? ""
    readonly property var log: Log.scoped("DankFmService")

    property bool socketReady: false
    property bool connected: false
    property int requestCounter: 0

    property string appVersion: Quickshell.env("DANKFM_VERSION") || "dev"
    property string appCommit: Quickshell.env("DANKFM_COMMIT") || ""
    property string appBuildTime: Quickshell.env("DANKFM_BUILD_TIME") || ""
    property int apiVersion: 1
    property var capabilities: ["ui"]

    signal windowActionRequested(string action)
    signal browseRequested(string path)

    Component.onCompleted: {
        if (socketPath.length > 0)
            socketProbe.running = true;
    }

    Process {
        id: socketProbe
        command: ["test", "-S", root.socketPath]
        running: false
        onExited: code => {
            if (code === 0) {
                root.socketReady = true;
                requestSocket.connected = true;
            }
        }
    }

    DankSocket {
        id: requestSocket
        path: root.socketPath
        connected: false

        onConnectionStateChanged: {
            root.connected = connected;
            if (connected) {
                subscribeSocket.connected = true;
            }
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0)
                    return;
                try {
                    JSON.parse(line);
                } catch (e) {
                    root.log.warn("bad response", line.substring(0, 200));
                }
            }
        }
    }

    DankSocket {
        id: subscribeSocket
        path: root.socketPath
        connected: false

        onConnectionStateChanged: {
            if (connected)
                root._sendSubscribe();
        }

        parser: SplitParser {
            onRead: line => root._handleLine(line);
        }
    }

    function _nextId() {
        requestCounter++;
        return Date.now() + requestCounter;
    }

    function _sendSubscribe() {
        subscribeSocket.send({
            "id": _nextId(),
            "method": "subscribe",
            "params": {
                "topics": ["ui"]
            }
        });
    }

    function _handleLine(line) {
        if (!line || line.length === 0)
            return;
        let msg;
        try {
            msg = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (msg.event === "ui")
            root._handleUI(msg.data || {});
    }

    function _handleUI(data) {
        const action = data.action || "";
        switch (action) {
        case "browse":
            browseRequested(data.path || "");
            break;
        case "show":
        case "hide":
        case "toggle":
            windowActionRequested(action);
            break;
        }
    }

    function sendRequest(method, params) {
        if (!connected)
            return;
        const req = {
            "id": _nextId(),
            "method": method
        };
        if (params)
            req.params = params;
        requestSocket.send(req);
    }

    function reportPath(path) {
        if (!path)
            return;
        sendRequest("ui.report", {
            "path": path
        });
    }
}
