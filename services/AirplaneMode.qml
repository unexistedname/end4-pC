pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Airplane mode state from rfkill. Hardware airplane keys (Fn+F8) toggle
 * rfkill in the kernel, so monitoring the event stream keeps the UI in sync
 * without a compositor keybind.
 */
Singleton {
    id: root

    property bool enabled: false
    property bool initialized: false

    function toggle(): void {
        setEnabled(!root.enabled);
    }

    function setEnabled(value): void {
        if (setRadioProc.running) return;
        setRadioProc.exec(["rfkill", value ? "block" : "unblock", "all"]);
    }

    function refresh(): void {
        if (stateProc.running) return;
        stateProc.running = true;
    }

    function applyState(contents): void {
        let next = false;
        try {
            const devices = JSON.parse(contents).rfkilldevices ?? [];
            const radios = devices.filter(device => ["wlan", "bluetooth", "wwan"].includes(device.type));
            next = radios.length > 0 && radios.every(device => device.soft === "blocked" || device.hard === "blocked");
        } catch (e) {
            console.warn("[AirplaneMode] Failed to read rfkill state:", e);
        }

        const changed = root.initialized && next !== root.enabled;
        root.enabled = next;
        if (changed) {
            Toast.show({
                icon: next ? "airplanemode_active" : "airplanemode_inactive",
                title: next ? Translation.tr("Airplane mode on") : Translation.tr("Airplane mode off")
            });
        }
        root.initialized = true;
    }

    Process {
        id: stateProc
        command: ["rfkill", "-J", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.applyState(text)
        }
    }

    Process {
        id: setRadioProc
        onExited: (exitCode, exitStatus) => root.refresh()
    }

    Process {
        id: monitorProc
        running: true
        command: ["rfkill", "event"]
        stdout: SplitParser {
            onRead: refreshDebounce.restart()
        }
    }

    Timer {
        id: refreshDebounce
        interval: 250
        onTriggered: root.refresh()
    }

    onEnabledChanged: Network.update()

    Component.onCompleted: root.refresh()

    IpcHandler {
        target: "airplane"

        function toggle(): void {
            root.toggle();
        }

        function enable(): void {
            root.setEnabled(true);
        }

        function disable(): void {
            root.setEnabled(false);
        }
    }
}
