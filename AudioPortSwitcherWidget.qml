import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    pluginId: "audioPortSwitcher"

    // --- State Properties ---
    property string defaultSource: ""
    property string activePort: ""
    property bool isInitialized: false

    // --- Configurable Settings (with defaults) ---
    property string internalMicLabel: "Laptop Mic"
    property string headsetMicLabel: "Headset Mic"
    property bool showNotifications: true
    property int barIconSize: 14


    // --- Initialization & Settings Sync ---
    Component.onCompleted: {
        loadSettings();
        // Start by getting the default source
        defaultSourceLoader.running = true;
    }

    onPluginServiceChanged: {
        if (pluginService)
            loadSettings();
    }

    Connections {
        target: pluginService
        enabled: pluginService !== null
        ignoreUnknownSignals: true

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === "audioPortSwitcher")
                root.loadSettings();
        }
    }

    function loadSettings() {
        if (!pluginService)
            return;
        internalMicLabel = pluginService.loadPluginData("audioPortSwitcher", "internalMicLabel", "Laptop Mic");
        headsetMicLabel = pluginService.loadPluginData("audioPortSwitcher", "headsetMicLabel", "Headset Mic");
        showNotifications = pluginService.loadPluginData("audioPortSwitcher", "showNotifications", true);
    }

    // --- Toggle Audio Port Logic ---
    function togglePort() {
        if (!root.defaultSource || !root.activePort) {
            // If default source is not yet resolved, try loading it again
            if (!root.defaultSource) {
                defaultSourceLoader.exec(["pactl", "get-default-source"]);
            }
            return;
        }

        var targetPort = (root.activePort === "analog-input-internal-mic")
            ? "analog-input-headset-mic"
            : "analog-input-internal-mic";

        portToggler.exec(["pactl", "set-source-port", root.defaultSource, targetPort]);
    }

    // --- Process Executions ---

    // 1. Get the name of the default active input source
    Process {
        id: defaultSourceLoader
        command: ["pactl", "get-default-source"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text.trim();
                if (raw) {
                    root.defaultSource = raw;
                    // Trigger active port query for this default source
                    activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
                }
            }
        }
    }

    // 2. Query active ports from sources JSON output
    Process {
        id: activePortLoader
        command: ["pactl", "--format=json", "list", "sources"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text;
                // Handle warning outputs before the JSON bracket starts
                var jsonStart = raw.indexOf('[');
                if (jsonStart !== -1) {
                    raw = raw.substring(jsonStart);
                }
                try {
                    var sources = JSON.parse(raw);
                    var found = false;
                    for (var i = 0; i < sources.length; i++) {
                        if (sources[i].name === root.defaultSource) {
                            root.activePort = sources[i].active_port;
                            found = true;
                            break;
                        }
                    }
                    if (found && !root.isInitialized) {
                        root.isInitialized = true;
                    }
                    // Start listener if it's not running
                    if (!eventListener.running) {
                        eventListener.running = true;
                    }
                } catch (e) {
                    console.error("AudioPortSwitcher: Failed to parse sources JSON", e);
                }
            }
        }
    }

    // 3. Persistent background listener for PipeWire events
    Process {
        id: eventListener
        command: ["sh", "-c", "pactl subscribe | grep --line-buffered source"]
        stdout: SplitParser {
            onRead: (data) => {
                // When an event happens, refresh the active port dynamically
                activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
            }
        }
    }

    // 4. One-shot command to toggle port
    Process {
        id: portToggler
    }

    // 5. System Notification process
    Process {
        id: notificationProcess
    }

    function sendNotification(title, message, icon) {
        if (!showNotifications) return;
        notificationProcess.exec(["notify-send", "-i", icon, title, message]);
    }

    // --- Reactive System Notification ---
    onActivePortChanged: {
        if (!root.isInitialized || root.activePort === "") return;

        var label = (root.activePort === "analog-input-headset-mic") ? root.headsetMicLabel : root.internalMicLabel;
        var icon = (root.activePort === "analog-input-headset-mic") ? "audio-headset" : "audio-input-microphone";
        
        sendNotification(
            "Conmutador de Audio", 
            "Puerto de entrada activo: " + label, 
            icon
        );
    }

    pillClickAction: function() { root.togglePort(); }

    horizontalBarPill: Component {
        RowLayout {
            id: horizLayout
            spacing: Theme.spacingS ? Theme.spacingS : 6

            DankIcon {
                id: horizIcon
                name: (root.activePort === "analog-input-headset-mic") ? "headset_mic" : "computer"
                size: (Theme.iconSize ? Theme.iconSize : 16) * 0.85
                color: (root.activePort === "analog-input-headset-mic") ? Theme.primary : Theme.surfaceVariantText

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            StyledText {
                text: (root.activePort === "analog-input-headset-mic") ? root.headsetMicLabel : root.internalMicLabel
                font.pixelSize: Theme.fontSizeSmall ? Theme.fontSizeSmall : 12
                color: Theme.surfaceText
            }
        }
    }

    verticalBarPill: Component {
        ColumnLayout {
            id: vertLayout
            spacing: Theme.spacingS ? Theme.spacingS : 6

            DankIcon {
                id: vertIcon
                name: (root.activePort === "analog-input-headset-mic") ? "headset_mic" : "computer"
                size: (Theme.iconSize ? Theme.iconSize : 16) * 0.85
                color: (root.activePort === "analog-input-headset-mic") ? Theme.primary : Theme.surfaceVariantText

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
