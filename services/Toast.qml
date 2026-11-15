pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Single-slot status toast. Any feature can call:
 *   Toast.show({ icon: "airplanemode_active", title: "Airplane mode on" })
 * A new call replaces the current toast and restarts its timer.
 */
Singleton {
    id: root

    property string icon: ""
    property string title: ""
    property string body: ""
    property int duration: 2500
    property bool visible: false

    function show(options) {
        root.icon = options.icon ?? "";
        root.title = options.title ?? "";
        root.body = options.body ?? "";
        root.duration = options.duration ?? 2500;
        root.visible = true;
        hideTimer.restart();
    }

    function hide() {
        root.visible = false;
        hideTimer.stop();
    }

    Timer {
        id: hideTimer
        interval: root.duration
        onTriggered: root.visible = false
    }
}
