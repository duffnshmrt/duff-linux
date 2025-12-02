pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    property string currentProvider: "hyprland"
    property var keybinds: ({"title": "", "provider": "", "binds": []})

    Process {
        id: getKeybinds
        running: false
        command: {
            let baseCmd = ["dms", "keybinds", "show"]
            if (root.overridePath) {
                baseCmd.push("--path")
                baseCmd.push(root.overridePath)
            }
            baseCmd.push(root.currentProvider)
            return baseCmd
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.keybinds = JSON.parse(text)
                } catch (e) {
                    console.error("[KeybindsService] Error parsing keybinds:", e)
                }
            }
        }

        onExited: (code) => {
            if (code !== 0 && code !== 15) {
                console.warn("[KeybindsService] Process exited with code:", code)
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: false
        onTriggered: {
            getKeybinds.running = true
        }
    }

    property string overridePath: ""

    function loadProvider(provider) {
        root.currentProvider = provider
        reload()
    }

    function loadProviderWithPath(provider, path) {
        root.currentProvider = provider
        root.overridePath = path
        reload()
    }

    function reload() {
        if (getKeybinds.running) {
            getKeybinds.running = false
        }
        Qt.callLater(function() {
            getKeybinds.running = true
        })
    }
}
