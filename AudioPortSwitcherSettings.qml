import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "audioPortSwitcher"

    StyledText {
        width: parent.width
        text: "Audio Port Switcher Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure icons, labels, and behavior for switching laptop and headset microphones on 3.5mm combo Jacks."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        id: notifyToggle
        settingKey: "showNotifications"
        label: "Show Notifications"
        description: "Display a system notification when switching audio ports."
        defaultValue: true
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    ToggleSetting {
        id: noLabelToggle
        settingKey: "noLabel"
        label: "Hide Text Label"
        description: "Only show the icon in the bar, hiding the text label."
        defaultValue: false
    }

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.outline
        opacity: 0.3
    }

    StyledText {
        width: parent.width
        text: "Icons & Labels (Material Symbols)"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "internalMicLabel"
        label: "Internal Mic Label"
        description: "Display label for the built-in laptop microphone."
        placeholder: "Laptop Mic"
        defaultValue: "Laptop Mic"
    }

    StringSetting {
        settingKey: "headsetMicLabel"
        label: "Headset Mic Label"
        description: "Display label for the external headset microphone."
        placeholder: "Headset Mic"
        defaultValue: "Headset Mic"
    }
}
