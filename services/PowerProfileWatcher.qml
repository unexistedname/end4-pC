pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/**
 * Toasts whenever the power profile changes, so changes made outside the
 * shell's own toggle are covered too.
 *
 * Fn+Q is handled by the firmware: it writes the ACPI platform profile and
 * UPower only catches up about a second later. Poll that file so the toast is
 * immediate; the UPower signal still covers systems without the file.
 */
Singleton {
    id: root

    property string lastTitle: ""
    property string platformProfile: ""
    property bool platformAvailable: true
    property bool platformReady: false

    function load(): void {}

    function notify(title, icon) {
        if (!title || title === root.lastTitle) return;
        root.lastTitle = title;
        Toast.show({ icon: icon, title: Translation.tr(title) });
    }

    function fromPowerProfiles(profile) {
        switch (profile) {
            case PowerProfile.PowerSaver: root.notify("Quiet mode", "energy_savings_leaf"); break;
            case PowerProfile.Performance: root.notify("Performance mode", "local_fire_department"); break;
            case PowerProfile.Balanced: root.notify("Balanced mode", "airwave"); break;
        }
    }

    function fromPlatformProfile(value) {
        switch (value) {
            case "low-power": root.notify("Quiet mode", "energy_savings_leaf"); break;
            case "performance":
            case "max-power": root.notify("Performance mode", "local_fire_department"); break;
            case "balanced": root.notify("Balanced mode", "airwave"); break;
        }
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            root.fromPowerProfiles(PowerProfiles.profile);
        }
    }

    FileView {
        id: platformFile
        path: "/sys/firmware/acpi/platform_profile"
        printErrors: false
        onLoadFailed: root.platformAvailable = false
        onLoaded: {
            const value = platformFile.text().trim();
            if (value === root.platformProfile) return;
            root.platformProfile = value;
            // The first read is the startup state, not a change.
            if (!root.platformReady) {
                root.platformReady = true;
                return;
            }
            root.fromPlatformProfile(value);
        }
    }

    Timer {
        interval: 250
        running: root.platformAvailable
        repeat: true
        onTriggered: platformFile.reload()
    }
}
