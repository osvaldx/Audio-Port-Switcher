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
    enabled: headsetHardwareConnected

    // --- State Properties ---
    property string defaultSource: ""
    property string activePort: ""
    property bool isInitialized: false
    property bool headsetHardwareConnected: true
    property bool activePortLoaderNeedsUpdate: false

    // --- Dynamic Detected Ports ---
    property string detectedInternalMicPort: ""
    property string detectedHeadsetMicPort: ""

    // --- Configurable Settings (with defaults) ---
    property string language: "es"
    property string internalMicLabel: "Laptop Mic"
    property string headsetMicLabel: "Headset Mic"
    property bool showNotifications: true
    property bool noLabel: false
    property int barIconSize: 14

    // --- Initialization & Settings Sync ---
    Component.onCompleted: {
        console.log("AudioPortSwitcher: Component.onCompleted");
        loadSettings();
        // Start by getting the default source
        defaultSourceLoader.running = true;
        // Start persistent audio event listener
        eventListener.running = true;
    }

    onPluginServiceChanged: {
        console.log("AudioPortSwitcher: onPluginServiceChanged");
        if (pluginService)
            loadSettings();
    }

    Connections {
        target: pluginService
        enabled: pluginService !== null
        ignoreUnknownSignals: true

        function onPluginDataChanged(changedPluginId) {
            console.log("AudioPortSwitcher: onPluginDataChanged", changedPluginId);
            if (changedPluginId === "audioPortSwitcher")
                root.loadSettings();
        }
    }

    function loadSettings() {
        if (!pluginService)
            return;
        language = pluginService.loadPluginData("audioPortSwitcher", "language", "es");
        internalMicLabel = pluginService.loadPluginData("audioPortSwitcher", "internalMicLabel", "Laptop Mic");
        headsetMicLabel = pluginService.loadPluginData("audioPortSwitcher", "headsetMicLabel", "Headset Mic");
        showNotifications = pluginService.loadPluginData("audioPortSwitcher", "showNotifications", true);
        noLabel = pluginService.loadPluginData("audioPortSwitcher", "noLabel", false);
        console.log("AudioPortSwitcher: Loaded settings:", language, internalMicLabel, headsetMicLabel, showNotifications, noLabel);
    }

    // --- Toggle Audio Port Logic ---
    function togglePort() {
        console.log("AudioPortSwitcher: togglePort() called. headsetHardwareConnected =", headsetHardwareConnected, "defaultSource =", root.defaultSource, "activePort =", root.activePort);
        if (!headsetHardwareConnected)
            return;
        if (!root.defaultSource || !root.activePort) {
            // If default source is not yet resolved, try loading it again
            if (!root.defaultSource) {
                console.log("AudioPortSwitcher: defaultSource not resolved, exec defaultSourceLoader");
                defaultSourceLoader.exec(["pactl", "get-default-source"]);
            }
            return;
        }

        // Abort and refresh if dynamic port names are not resolved yet
        if (!root.detectedHeadsetMicPort || !root.detectedInternalMicPort) {
            console.log("AudioPortSwitcher: Dynamic ports not resolved yet, aborting and refreshing");
            activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
            return;
        }

        var targetPort = (root.activePort === root.detectedInternalMicPort)
            ? root.detectedHeadsetMicPort
            : root.detectedInternalMicPort;

        console.log("AudioPortSwitcher: Toggling port to", targetPort);
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
                console.log("AudioPortSwitcher: defaultSourceLoader finished. stdout =", raw);
                if (raw) {
                    root.defaultSource = raw;
                    // Trigger active port query for this default source
                    if (!activePortLoader.running) {
                        activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
                    } else {
                        root.activePortLoaderNeedsUpdate = true;
                    }
                }
            }
        }
    }

    // 2. Query active ports and check availability from sources JSON output
    Process {
        id: activePortLoader
        command: ["pactl", "--format=json", "list", "sources"]
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = text;
                console.log("AudioPortSwitcher: activePortLoader finished.");
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
                            var src = sources[i];
                            root.activePort = src.active_port;
                            console.log("AudioPortSwitcher: Found source active port =", root.activePort);
                            
                            // Auto-detect port names dynamically
                            root.detectedHeadsetMicPort = "";
                            root.detectedInternalMicPort = "";
                            if (src.ports) {
                                for (var j = 0; j < src.ports.length; j++) {
                                    var portName = src.ports[j].name;
                                    if (portName.indexOf("headset-mic") !== -1 || portName.indexOf("headset") !== -1) {
                                        root.detectedHeadsetMicPort = portName;
                                    } else if (portName.indexOf("internal-mic") !== -1 || portName.indexOf("internal") !== -1 || portName.indexOf("front-mic") !== -1) {
                                        root.detectedInternalMicPort = portName;
                                    }
                                }
                            }
                            if (root.detectedHeadsetMicPort !== "" && root.detectedInternalMicPort === "") {
                                root.detectedInternalMicPort = src.active_port;
                                console.log("AudioPortSwitcher: Fallback internal mic port assigned from active_port =", root.detectedInternalMicPort);
                            }
                            console.log("AudioPortSwitcher: Detected internal mic port =", root.detectedInternalMicPort);
                            console.log("AudioPortSwitcher: Detected headset mic port =", root.detectedHeadsetMicPort);

                            // Check headset mic port availability generically
                            var hasHeadsetPort = (root.detectedHeadsetMicPort !== "");
                            var isHeadsetAvailable = true;
                            if (hasHeadsetPort && src.ports) {
                                for (var j = 0; j < src.ports.length; j++) {
                                    if (src.ports[j].name === root.detectedHeadsetMicPort) {
                                        if (src.ports[j].availability === "not available") {
                                            isHeadsetAvailable = false;
                                        }
                                        break;
                                    }
                                }
                            }
                            
                            if (hasHeadsetPort) {
                                root.headsetHardwareConnected = isHeadsetAvailable;
                            } else {
                                // Generic fallback: if default source doesn't have an analog headset port (e.g. USB/Bluetooth headset), enable the switcher
                                root.headsetHardwareConnected = true;
                            }
                            
                            console.log("AudioPortSwitcher: headsetHardwareConnected =", root.headsetHardwareConnected);
                            found = true;
                            break;
                        }
                    }
                    if (found && !root.isInitialized) {
                        root.isInitialized = true;
                    }
                } catch (e) {
                    console.error("AudioPortSwitcher: Failed to parse sources JSON", e);
                }

                // Process queued update request if any arrived while we were running
                if (root.activePortLoaderNeedsUpdate) {
                    root.activePortLoaderNeedsUpdate = false;
                    activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
                }
            }
        }
    }

    // 3. Persistent event listener for PulseAudio/PipeWire events
    Process {
        id: eventListener
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: (data) => {
                // Whenever any event occurs, query latest source state to update UI in real-time
                if (activePortLoader.running) {
                    root.activePortLoaderNeedsUpdate = true;
                } else {
                    activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
                }
            }
        }
    }

    function updateHardwareStatus() {
        console.log("AudioPortSwitcher: updateHardwareStatus() called");
        if (activePortLoader.running) {
            root.activePortLoaderNeedsUpdate = true;
        } else {
            activePortLoader.exec(["pactl", "--format=json", "list", "sources"]);
        }
    }

    Connections {
        target: AudioService
        ignoreUnknownSignals: true
        
        function onSourceChanged() {
            console.log("AudioPortSwitcher: AudioService onSourceChanged");
            if (!defaultSourceLoader.running) {
                defaultSourceLoader.exec(["pactl", "get-default-source"]);
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
        notificationProcess.exec(["notify-send", "-a", "Audio Port Switcher", "-i", icon, title, message]);
    }

    // --- Reactive System Notification ---
    onActivePortChanged: {
        console.log("AudioPortSwitcher: activePort changed to", root.activePort);
        if (!root.isInitialized || root.activePort === "") return;

        var label = (root.activePort === root.detectedHeadsetMicPort) ? root.headsetMicLabel : root.internalMicLabel;
        var icon = (root.activePort === root.detectedHeadsetMicPort) ? "audio-headset" : "audio-input-microphone";
        
        var title = (root.language === "es") ? "Conmutador de Audio" : "Audio Port Switcher";
        var message = (root.language === "es") ? "Puerto de entrada activo: " : "Active input port: ";

        sendNotification(
            title, 
            message + label, 
            icon
        );
    }

    pillClickAction: function() { root.togglePort(); }

    horizontalBarPill: Component {
        RowLayout {
            id: horizLayout
            spacing: (root.noLabel || !textLabel.visible) ? 0 : (Theme.spacingS ? Theme.spacingS : 6)
            opacity: root.enabled ? 1.0 : 0.4
            enabled: root.enabled

            DankIcon {
                id: horizIcon
                name: (root.enabled && root.activePort === root.detectedHeadsetMicPort) ? "headset_mic" : "computer"
                size: (Theme.iconSize ? Theme.iconSize : 16) * 0.85
                color: (root.enabled && root.activePort === root.detectedHeadsetMicPort) ? Theme.primary : Theme.surfaceVariantText

                Behavior on color { ColorAnimation { duration: 200 } }
            }

            StyledText {
                id: textLabel
                visible: !root.noLabel
                text: (root.enabled && root.activePort === root.detectedHeadsetMicPort) ? root.headsetMicLabel : root.internalMicLabel
                font.pixelSize: Theme.fontSizeSmall ? Theme.fontSizeSmall : 12
                color: Theme.surfaceText
            }
        }
    }

    verticalBarPill: Component {
        ColumnLayout {
            id: vertLayout
            spacing: Theme.spacingS ? Theme.spacingS : 6
            opacity: root.enabled ? 1.0 : 0.4
            enabled: root.enabled

            DankIcon {
                id: vertIcon
                name: (root.enabled && root.activePort === root.detectedHeadsetMicPort) ? "headset_mic" : "computer"
                size: (Theme.iconSize ? Theme.iconSize : 16) * 0.85
                color: (root.enabled && root.activePort === root.detectedHeadsetMicPort) ? Theme.primary : Theme.surfaceVariantText

                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }
}
