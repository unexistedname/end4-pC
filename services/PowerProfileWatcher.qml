pragma Singleton
pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Services.UPower

/**
 * Toasts whenever UPower reports a power profile change, so changes made
 * outside the shell's own toggle (Fn+Q, powerprofilesctl) are covered too.
 */
Singleton {
    id: root

    function load(): void {}

    function profileInfo() {
        switch (PowerProfiles.profile) {
            case PowerProfile.PowerSaver: return { icon: "energy_savings_leaf", title: "Quiet mode" };
            case PowerProfile.Performance: return { icon: "local_fire_department", title: "Performance mode" };
        }
        return { icon: "airwave", title: "Balanced mode" };
    }

    Connections {
        target: PowerProfiles
        function onProfileChanged() {
            const profile = root.profileInfo();
            Toast.show({ icon: profile.icon, title: Translation.tr(profile.title) });
        }
    }
}
