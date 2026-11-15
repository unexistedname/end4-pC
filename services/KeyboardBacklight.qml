pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Keyboard backlight level from the LED class device, so Fn+Space needs no
 * compositor keybind. The firmware updates the LED from the kernel without
 * touching the sysfs file from userspace, so inotify never fires: poll it.
 */
Singleton {
    id: root

    readonly property string device: "platform::kbd_backlight"
    readonly property string brightnessPath: `/sys/class/leds/${root.device}/brightness`
    readonly property string maxBrightnessPath: `/sys/class/leds/${root.device}/max_brightness`

    property int level: 0
    property int maxLevel: 1
    property bool initialized: false

    // FileView loads on its own; this only instantiates the singleton.
    function load(): void {}

    function applyLevel(contents): void {
        const next = parseInt(contents.trim(), 10);
        if (isNaN(next)) return;

        const changed = root.initialized && next !== root.level;
        root.level = next;
        if (changed) {
            Toast.show({
                icon: next <= 0 ? "backlight_high_off" : (next >= root.maxLevel ? "backlight_high" : "backlight_low"),
                title: Translation.tr("Keyboard backlight"),
                body: next <= 0 ? Translation.tr("Off") : `${next} / ${root.maxLevel}`,
            });
        }
        root.initialized = true;
    }

    function applyMax(contents): void {
        const max = parseInt(contents.trim(), 10);
        if (!isNaN(max) && max > 0) root.maxLevel = max;
    }

    FileView {
        id: levelFile
        path: root.brightnessPath
        printErrors: false
        onLoaded: root.applyLevel(levelFile.text())
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: levelFile.reload()
    }

    FileView {
        id: maxFile
        path: root.maxBrightnessPath
        printErrors: false
        onLoaded: root.applyMax(maxFile.text())
    }
}
