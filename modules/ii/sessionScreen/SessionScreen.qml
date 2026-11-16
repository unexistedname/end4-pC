import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property string focusedScreenName: WM.compositor === "niri"
        ? (NiriBackend.focusedMonitor?.name ?? "")
        : (Hyprland.focusedMonitor?.name ?? "")

    property var focusedScreen: Quickshell.screens.find(s => s.name === root.focusedScreenName)
        ?? Quickshell.screens[0]

    readonly property string sessionPosition: Config.options?.appearance?.session?.position ?? "bottom-center"
    readonly property bool sideDocked: sessionPosition === "left-center" || sessionPosition === "right-center"

    // Keeps the window mapped while the exit animation plays.
    property bool sessionVisible: GlobalStates.sessionOpen

    Connections {
        target: GlobalStates
        function onSessionOpenChanged() {
            if (GlobalStates.sessionOpen) {
                closeTimer.stop();
                root.sessionVisible = true;
            } else if (root.sessionVisible) {
                closeTimer.restart();
            }
        }
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                GlobalStates.sessionOpen = false;
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Appearance.animation.sidebarSlideExit.duration + 20
        onTriggered: root.sessionVisible = false
    }

    Loader {
        id: sessionLoader
        active: root.sessionVisible
        onActiveChanged: {
            if (sessionLoader.active && GlobalStates.sessionOpen)
                SessionWarnings.refresh();
        }

        sourceComponent: PanelWindow { // Session menu
            id: sessionRoot
            property bool entered: false
            property string subtitle

            // Declaration order = focus order in the action grid (row-major).
            readonly property var actionButtons: [
                sessionLock, sessionSleep, sessionLogout, sessionTaskManager,
                sessionHibernate, sessionShutdown, sessionReboot, sessionFirmwareReboot
            ]

            screen: root.focusedScreen
            visible: true

            function hide() {
                GlobalStates.sessionOpen = false;
            }

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: GlobalStates.sessionOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            implicitWidth: root.focusedScreen?.width ?? 0
            implicitHeight: root.focusedScreen?.height ?? 0

            // Let the window map before animating in.
            Timer {
                interval: 16
                running: true
                onTriggered: sessionRoot.entered = true
            }

            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.m3colors.m3background, Appearance.m3colors.darkmode ? 0.05 : 0.12)
                opacity: sessionRoot.entered && GlobalStates.sessionOpen ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.duration : Appearance.animation.sidebarSlideExit.duration
                        easing.type: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.type : Appearance.animation.sidebarSlideExit.type
                        easing.bezierCurve: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.bezierCurve : Appearance.animation.sidebarSlideExit.bezierCurve
                    }
                }
            }

            MouseArea {
                id: sessionMouseArea
                anchors.fill: parent
                onClicked: sessionRoot.hide()
            }

            Item {
                id: sheetWrapper
                readonly property real edgeGap: Appearance.sizes.elevationMargin * 4
                readonly property real barGap: Config.options.bar.autoHide.enable ? 0 : Appearance.sizes.barHeight

                readonly property real restX: root.sessionPosition === "left-center"
                    ? Appearance.sizes.elevationMargin * 2
                    : root.sessionPosition === "right-center"
                        ? sessionRoot.width - width - Appearance.sizes.elevationMargin * 2
                        : (sessionRoot.width - width) / 2
                readonly property real restY: root.sessionPosition === "top-center"
                    ? edgeGap + (Config.options.bar.bottom ? 0 : barGap)
                    : root.sessionPosition === "bottom-center"
                        ? sessionRoot.height - height - edgeGap - (Config.options.bar.bottom ? barGap : 0)
                        : (sessionRoot.height - height) / 2
                readonly property real hiddenX: root.sessionPosition === "left-center" ? -width - edgeGap
                    : root.sessionPosition === "right-center" ? sessionRoot.width + edgeGap
                    : restX
                readonly property real hiddenY: root.sessionPosition === "top-center" ? -height - edgeGap
                    : root.sessionPosition === "bottom-center" ? sessionRoot.height + edgeGap
                    : restY

                width: Math.min(contentColumn.implicitWidth + 40, sessionRoot.width - edgeGap)
                height: contentColumn.implicitHeight + 32
                x: sessionRoot.entered && GlobalStates.sessionOpen ? restX : hiddenX
                y: sessionRoot.entered && GlobalStates.sessionOpen ? restY : hiddenY

                Behavior on x {
                    NumberAnimation {
                        duration: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.duration : Appearance.animation.sidebarSlideExit.duration
                        easing.type: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.type : Appearance.animation.sidebarSlideExit.type
                        easing.bezierCurve: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.bezierCurve : Appearance.animation.sidebarSlideExit.bezierCurve
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.duration : Appearance.animation.sidebarSlideExit.duration
                        easing.type: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.type : Appearance.animation.sidebarSlideExit.type
                        easing.bezierCurve: GlobalStates.sessionOpen ? Appearance.animation.sidebarSlideEnter.bezierCurve : Appearance.animation.sidebarSlideExit.bezierCurve
                    }
                }

                StyledRectangularShadow {
                    target: sheetBackground
                }
                Rectangle {
                    id: sheetBackground
                    anchors.fill: parent
                    color: Appearance.colors.colUiBackground
                    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 5
                    border.width: 1
                    border.color: ColorUtils.transparentize(Appearance.colors.colLayer0Border, 0.8)

                    WindowGlass {
                        anchors.fill: parent
                        glassEnabled: (parent?.color.a ?? 0) > 0
                        cardRadius: parent?.radius ?? 0
                        tint: parent?.color ?? 'transparent'
                    }

                    // Swallow clicks on the sheet itself; only the backdrop closes.
                    MouseArea {
                        anchors.fill: parent
                    }
                }

                ColumnLayout { // Content column
                    id: contentColumn
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    spacing: 12

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            sessionRoot.hide();
                            event.accepted = true;
                            return;
                        }
                        let dRow = 0, dCol = 0;
                        if (event.key === Qt.Key_Left) dCol = -1;
                        else if (event.key === Qt.Key_Right) dCol = 1;
                        else if (event.key === Qt.Key_Up) dRow = -1;
                        else if (event.key === Qt.Key_Down) dRow = 1;
                        else return;

                        const buttons = sessionRoot.actionButtons;
                        const cols = root.sideDocked ? 2 : 4;
                        const current = Math.max(0, buttons.findIndex(b => b.activeFocus));
                        const row = Math.floor(current / cols) + dRow;
                        const col = (current % cols) + dCol;
                        if (row < 0 || col < 0 || col >= cols) return;
                        const target = buttons[row * cols + col];
                        if (target) target.forceActiveFocus();
                        event.accepted = true;
                    }

                    StyledText {
                        // Title
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.title
                            variableAxes: Appearance.font.variableAxes.title
                        }
                        text: Translation.tr("Session")
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: root.sideDocked ? 2 : 4
                        rowSpacing: 8
                        columnSpacing: 8

                        SessionActionButton {
                            id: sessionLock
                            focus: sessionRoot.visible
                            buttonIcon: "lock"
                            buttonText: Translation.tr("Lock")
                            onClicked: {
                                Session.lock();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionSleep
                            buttonIcon: "dark_mode"
                            buttonText: Translation.tr("Sleep")
                            onClicked: {
                                Session.suspend();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionLogout
                            buttonIcon: "logout"
                            buttonText: Translation.tr("Logout")
                            onClicked: {
                                Session.logout();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionTaskManager
                            buttonIcon: "browse_activity"
                            buttonText: Translation.tr("Task Manager")
                            onClicked: {
                                Session.launchTaskManager();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionHibernate
                            buttonIcon: "downloading"
                            buttonText: Translation.tr("Hibernate")
                            onClicked: {
                                Session.hibernate();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionShutdown
                            buttonIcon: "power_settings_new"
                            buttonText: Translation.tr("Shutdown")
                            onClicked: {
                                Session.poweroff();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionReboot
                            buttonIcon: "restart_alt"
                            buttonText: Translation.tr("Reboot")
                            onClicked: {
                                Session.reboot();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                        SessionActionButton {
                            id: sessionFirmwareReboot
                            buttonIcon: "settings_applications"
                            buttonText: Translation.tr("Reboot to firmware settings")
                            onClicked: {
                                Session.rebootToFirmware();
                                sessionRoot.hide();
                            }
                            onFocusChanged: {
                                if (focus)
                                    sessionRoot.subtitle = buttonText;
                            }
                        }
                    }

                    DescriptionLabel {
                        Layout.alignment: Qt.AlignHCenter
                        text: sessionRoot.subtitle
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        Loader {
                            Layout.alignment: Qt.AlignHCenter
                            active: SessionWarnings.downloadRunning
                            visible: active
                            sourceComponent: DescriptionLabel {
                                text: Translation.tr("There might be a download in progress. Check your Downloads folder.")
                                textColor: Appearance.m3colors.m3onErrorContainer
                                color: Appearance.m3colors.m3errorContainer
                            }
                        }

                        Loader {
                            Layout.alignment: Qt.AlignHCenter
                            active: SessionWarnings.packageManagerRunning
                            visible: active
                            sourceComponent: DescriptionLabel {
                                text: Translation.tr("Your package manager is running")
                                textColor: Appearance.m3colors.m3onErrorContainer
                                color: Appearance.m3colors.m3errorContainer
                            }
                        }
                    }
                }
            }
        }
    }

    component DescriptionLabel: Rectangle {
        id: descriptionLabel
        property string text
        property color textColor: Appearance.colors.colOnTooltip
        color: Appearance.colors.colTooltip
        clip: true
        radius: Appearance.rounding.normal
        implicitHeight: descriptionLabelText.implicitHeight + 10 * 2
        implicitWidth: descriptionLabelText.implicitWidth + 15 * 2

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        StyledText {
            id: descriptionLabelText
            anchors.centerIn: parent
            color: descriptionLabel.textColor
            text: descriptionLabel.text
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
        }

        function close(): void {
            GlobalStates.sessionOpen = false;
        }

        function open(): void {
            GlobalStates.sessionOpen = true;
        }
    }

    CompositorGlobalShortcut {
        name: "sessionToggle"
        description: "Toggles session screen on press"

        onPressed: {
            if (Config.options.bar.layouts.middleLayout.includes("dynamicIsland")) {
                GlobalStates.diSessionOpen = !GlobalStates.diSessionOpen;
            } else {
                GlobalStates.sessionOpen = !GlobalStates.sessionOpen;
            }
        }
    }

    CompositorGlobalShortcut {
        name: "sessionOpen"
        description: "Opens session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = true;
        }
    }

    CompositorGlobalShortcut {
        name: "sessionClose"
        description: "Closes session screen on press"

        onPressed: {
            GlobalStates.sessionOpen = false;
        }
    }
}
