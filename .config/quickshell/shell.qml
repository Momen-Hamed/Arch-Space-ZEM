import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Layouts
import QtQuick
import Quickshell.Io


PanelWindow {
 id: root

     property color colBg: "#1a1b26"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    property int cpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0

 Process {
    id: cpuProc
    command: ["sh", "-c", "head -1 /proc/stat"]
    stdout: SplitParser {
        onRead: data => {
            if (!data) return
            var p = data.trim().split(/\s+/)
            var idle = parseInt(p[4]) + parseInt(p[5])
            var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
            if (lastCpuTotal > 0) {
                cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
            }
            lastCpuTotal = total
            lastCpuIdle = idle
        }
        
    }
    Component.onCompleted: running = true
    
}
Timer {
    interval: 2000        // Every 2 seconds
    running: true         // Start immediately
    repeat: true          // Keep going forever
    onTriggered: cpuProc.running = true
}

 anchors.top: true
 anchors.left: true
 anchors.right: true
 implicitHeight: 30
 // color: "rgba(0, 0, 0, 0)"
 RowLayout {
  anchors.fill: parent
   anchors.margins: 8
    Repeater {
     model: 8
     Text {
            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: index + 1
                                color: isActive ? "#0db9d7" : (ws ? "#7aa2f7" : "#444b6a")
                                                font {
             pixelSize: 14; bold: true; italic: true;
                                                   }
                           MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }

         }
   }
           Item { Layout.fillWidth: true }
          Text {
           text: "CPU: " + cpuUsage + "%"
           color: root.colYellow
          }
 }
}