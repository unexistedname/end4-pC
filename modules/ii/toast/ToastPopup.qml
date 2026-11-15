import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * Bottom-center status toast. Styling mirrors the notification popup (glass
 * surface, shadow) and the OSD (tonal icon circle). Content comes from the
 * reusable Toast service so other features can show their own feedback.
 */
Scope {
    id: root

    PanelWindow {
        id: popup
        visible: Toast.visible || card.opacity > 0
        screen: Quickshell.screens.find(s => s.name === WM.focusedMonitor?.name) ?? null
        color: "transparent"

        WlrLayershell.namespace: "quickshell:toast"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        anchors.bottom: true
        margins.bottom: (Config.options.bar.bottom ? Appearance.sizes.barHeight : 0) + 24

        implicitWidth: card.implicitWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: card.implicitHeight + Appearance.sizes.elevationMargin * 2

        mask: Region {
            item: card
        }

        Item {
            anchors.fill: parent

            StyledRectangularShadow {
                target: card
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Toast.visible ? 0 : 10
                implicitWidth: 340
                implicitHeight: contentRow.implicitHeight + 24
                radius: Appearance.rounding.normal
                color: Appearance.colors.colBackgroundSurfaceContainer
                opacity: Toast.visible ? 1 : 0

                WindowGlass {
                    anchors.fill: parent
                    glassEnabled: (parent?.color.a ?? 0) > 0
                    cardRadius: parent?.radius ?? 0
                    tint: parent?.color ?? 'transparent'
                }

                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on anchors.verticalCenterOffset {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Toast.hide()
                }

                RowLayout {
                    id: contentRow
                    anchors.centerIn: parent
                    width: parent.width - 24
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: height / 2
                        color: Appearance.colors.colSecondaryContainer

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: Toast.icon
                            iconSize: 24
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        StyledText {
                            Layout.fillWidth: true
                            text: Toast.title
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: Toast.body !== ""
                            text: Toast.body
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
