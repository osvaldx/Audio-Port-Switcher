import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "audioPortSwitcher"

    property string currentLanguage: "es"

    Component.onCompleted: {
        updateLanguage();
    }

    onPluginServiceChanged: {
        updateLanguage();
    }

    Connections {
        target: root.pluginService
        enabled: root.pluginService !== null
        ignoreUnknownSignals: true
        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                root.updateLanguage();
            }
        }
    }

    function updateLanguage() {
        if (root.pluginService) {
            root.currentLanguage = root.pluginService.loadPluginData(root.pluginId, "language", "es");
        }
    }    readonly property var translations: {
        "es": {
            "title": "Configuración del Conmutador de Puerto de Audio",
            "desc": "Configura iconos, etiquetas y comportamiento para cambiar entre los micrófonos de la laptop y del auricular en conectores combo de 3.5 mm.",
            "languageLabel": "Idioma",
            "languageDesc": "Selecciona el idioma de la interfaz del plugin y las notificaciones.",
            "showNotificationsLabel": "Mostrar Notificaciones",
            "showNotificationsDesc": "Muestra una notificación del sistema al cambiar de puerto de audio.",
            "hideTextLabel": "Ocultar Etiqueta de Texto",
            "hideTextDesc": "Muestra solo el icono en la barra, ocultando la etiqueta de texto.",
            "iconsLabelsHeader": "Iconos y Etiquetas (Símbolos Material)",
            "internalMicLabel": "Etiqueta del Mic Interno",
            "internalMicDesc": "Etiqueta que se muestra para el micrófono incorporado de la notebook.",
            "headsetMicLabel": "Etiqueta del Mic del Auricular",
            "headsetMicDesc": "Etiqueta que se muestra para el micrófono externo del auricular."
        },
        "en": {
            "title": "Audio Port Switcher Settings",
            "desc": "Configure icons, labels, and behavior for switching laptop and headset microphones on 3.5mm combo Jacks.",
            "languageLabel": "Language",
            "languageDesc": "Select the language for the plugin interface and notifications.",
            "showNotificationsLabel": "Show Notifications",
            "showNotificationsDesc": "Display a system notification when switching audio ports.",
            "hideTextLabel": "Hide Text Label",
            "hideTextDesc": "Only show the icon in the bar, hiding the text label.",
            "iconsLabelsHeader": "Icons & Labels (Material Symbols)",
            "internalMicLabel": "Internal Mic Label",
            "internalMicDesc": "Display label for the built-in laptop microphone.",
            "headsetMicLabel": "Headset Mic Label",
            "headsetMicDesc": "Display label for the external headset microphone."
        }
    }

    function t(key) {
        var lang = currentLanguage === "en" ? "en" : "es";
        return translations[lang][key];
    }

    StyledText {
        width: parent.width
        text: root.t("title")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: root.t("desc")
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

    SelectionSetting {
        settingKey: "language"
        label: root.t("languageLabel")
        description: root.t("languageDesc")
        defaultValue: "es"
        options: [
            { label: "Español", value: "es" },
            { label: "English", value: "en" }
        ]
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
        label: root.t("showNotificationsLabel")
        description: root.t("showNotificationsDesc")
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
        label: root.t("hideTextLabel")
        description: root.t("hideTextDesc")
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
        text: root.t("iconsLabelsHeader")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StringSetting {
        settingKey: "internalMicLabel"
        label: root.t("internalMicLabel")
        description: root.t("internalMicDesc")
        placeholder: "Laptop Mic"
        defaultValue: "Laptop Mic"
    }

    StringSetting {
        settingKey: "headsetMicLabel"
        label: root.t("headsetMicLabel")
        description: root.t("headsetMicDesc")
        placeholder: "Headset Mic"
        defaultValue: "Headset Mic"
    }
}
