pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Touchpad toggle through Hyprland's per-device config. Hyprland cannot report
 * the per-device `enabled` state back, so it is kept here and assumed enabled
 * at startup.
 */
Singleton {
    id: root

    property bool enabled: true
    property var deviceNames: []
    property double lastChange: 0

    // Hyprland only has `eval` for config in this build, `keyword` is gone.
    function setEnabled(value): void {
        if (root.deviceNames.length === 0) return;
        // Fn+F10 may report several keysyms for one press.
        if (Date.now() - root.lastChange < 350) return;
        root.lastChange = Date.now();
        const calls = root.deviceNames
            .map(name => `hl.device({ name = '${name}', enabled = ${value} })`)
            .join("; ");
        setProc.exec(["hyprctl", "eval", calls]);
        root.enabled = value;
        Toast.show({
            icon: value ? "touchpad_mouse" : "touchpad_mouse_off",
            title: Translation.tr("Touchpad"),
            body: value ? Translation.tr("Enabled") : Translation.tr("Disabled"),
        });
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    // Disable every node of the same touchpad, not just the `-touchpad` one.
    function applyDevices(contents): void {
        try {
            const mice = JSON.parse(contents).mice ?? [];
            const touchpad = mice.find(mouse => mouse.name.includes("touchpad"));
            if (!touchpad) return;
            const prefix = touchpad.name.replace(/-touchpad.*$/, "");
            root.deviceNames = mice.filter(mouse => mouse.name.startsWith(prefix)).map(mouse => mouse.name);
        } catch (e) {
            console.warn("[Touchpad] Failed to read devices:", e);
        }
    }

    // Instantiates the singleton and discovers the device names at startup.
    function load(): void {
        if (deviceProc.running || root.deviceNames.length > 0) return;
        deviceProc.running = true;
    }

    Process {
        id: deviceProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.applyDevices(text)
        }
    }

    Process {
        id: setProc
    }

    IpcHandler {
        target: "touchpad"

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
