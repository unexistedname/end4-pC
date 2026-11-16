import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

GroupButton {
    id: button

    property string buttonIcon
    property string buttonText
    property bool keyboardDown: false
    property real cellWidth: 96
    property real cellHeight: 96

    baseWidth: cellWidth
    baseHeight: cellHeight
    // Keep the cell fixed while the bounce animates implicitWidth.
    Layout.preferredWidth: cellWidth
    Layout.preferredHeight: cellHeight
    padding: 0
    bounce: true
    buttonRadius: Appearance.rounding.normal
    buttonRadiusPressed: Appearance.rounding.normal

    toggled: button.focus || button.keyboardDown
    colBackground: Appearance.colors.colLayer1
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colBackgroundActive: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colPrimary
    colBackgroundToggledHover: Appearance.colors.colPrimaryHover
    colBackgroundToggledActive: Appearance.colors.colPrimaryActive
    property color colText: button.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer0

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = true
            button.click()
            event.accepted = true
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            keyboardDown = false
            event.accepted = true
        }
    }

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fill: button.toggled ? 1 : 0
        iconSize: Appearance.font.pixelSize.huge + 12
        color: button.colText
        text: button.buttonIcon
    }

    StyledToolTip {
        text: button.buttonText
    }
}
