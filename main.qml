import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5

ApplicationWindow {
    id: app
    
    property var latestStats: ({"cpu":{"pct":0},"ram":{"pct":0},"battery":{"capacity":0}})

    cover: Component {
        CoverBackground {
            Column {
                anchors.centerIn: parent
                width: parent.width - Theme.paddingLarge * 2
                spacing: Theme.paddingSmall

                // CPU% — big and clear
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (app.latestStats.cpu ? app.latestStats.cpu.pct : "0") + "%"
                    color: {
                        var pct = app.latestStats.cpu ? app.latestStats.cpu.pct : 0
                        return pct > 80 ? "#ff4d4d" : pct > 50 ? "#ffaa00" : Theme.highlightColor
                    }
                    font.pixelSize: Theme.fontSizeExtraLarge * 1.4
                    font.bold: true
                }

                // CPU label
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "CPU"
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }

                // Visual bar
                Rectangle {
                    width: parent.width
                    height: Theme.paddingMedium
                    color: Theme.rgba(Theme.secondaryColor, 0.15)
                    radius: height / 2

                    Rectangle {
                        width: parent.width * (app.latestStats.cpu ? app.latestStats.cpu.pct : 0) / 100
                        height: parent.height
                        radius: height / 2
                        color: {
                            var pct = app.latestStats.cpu ? app.latestStats.cpu.pct : 0
                            return pct > 80 ? "#ff4d4d" : pct > 50 ? "#ffaa00" : "#00cc66"
                        }
                    }
                }

                // RAM + Battery in one compact line
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "RAM " + (app.latestStats.ram ? app.latestStats.ram.pct : "0") +
                          "%   BAT " + (app.latestStats.battery ? app.latestStats.battery.capacity : "0") + "%"
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                }
            }

            CoverActionList {
                CoverAction {
                    iconSource: "image://theme/icon-cover-refresh"
                    onTriggered: {
                        python.call("backend.get_all", [], function(result) {
                            updateStats(result)
                        })
                    }
                }
            }
        }
    }

    initialPage: Page {
        id: page
        allowedOrientations: Orientation.All

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: column.height + Theme.paddingLarge

            PullDownMenu {
                MenuItem {
                    text: "Refresh"
                    onClicked: {
                        python.call("backend.get_all", [], function(result) {
                            updateStats(result)
                        })
                    }
                }
            }

            Column {
                id: column
                width: parent.width
                spacing: Theme.paddingMedium

                PageHeader {
                    title: "System Ninja"
                }

                // CPU
                SectionHeader { text: "CPU" }
                Item {
                    height: cpuLabel.height + cpuBar.height + Theme.paddingSmall
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x

                    Label {
                        id: cpuLabel
                        text: "--%"
                        font.pixelSize: Theme.fontSizeHuge
                        color: Theme.highlightColor
                    }
                    Label {
                        anchors.right: parent.right
                        anchors.baseline: cpuLabel.baseline
                        id: cpuDetail
                        text: "-- cores"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                    }
                    ProgressBar {
                        id: cpuBar
                        anchors.top: cpuLabel.bottom
                        anchors.topMargin: Theme.paddingSmall
                        width: parent.width
                        minimumValue: 0
                        maximumValue: 100
                        value: 0
                    }
                }

                Separator { 
                    width: parent.width 
                    color: Theme.secondaryHighlightColor 
                    horizontalAlignment: Qt.AlignHCenter 
                }

                // RAM
                SectionHeader { text: "Memory" }
                Item {
                    height: ramLabel.height + ramBar.height + Theme.paddingSmall
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x

                    Label {
                        id: ramLabel
                        text: "-- / -- MB"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                    }
                    ProgressBar {
                        id: ramBar
                        anchors.top: ramLabel.bottom
                        anchors.topMargin: Theme.paddingSmall
                        width: parent.width
                        minimumValue: 0
                        maximumValue: 100
                        value: 0
                    }
                }

                Separator { 
                    width: parent.width 
                    color: Theme.secondaryHighlightColor 
                    horizontalAlignment: Qt.AlignHCenter 
                }

                // Storage
                SectionHeader { text: "Storage" }
                Item {
                    height: storageLabel.height + storageBar.height + Theme.paddingSmall
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x

                    Label {
                        id: storageLabel
                        text: "-- / -- GB"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                    }
                    ProgressBar {
                        id: storageBar
                        anchors.top: storageLabel.bottom
                        anchors.topMargin: Theme.paddingSmall
                        width: parent.width
                        minimumValue: 0
                        maximumValue: 100
                        value: 0
                    }
                }

                Separator { 
                    width: parent.width 
                    color: Theme.secondaryHighlightColor 
                    horizontalAlignment: Qt.AlignHCenter 
                }

                // Battery
                SectionHeader { text: "Battery" }
                Row {
                    x: Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium
                    Label {
                        id: batteryLabel
                        text: "--%"
                        font.pixelSize: Theme.fontSizeHuge
                        color: Theme.highlightColor
                    }
                    Label {
                        id: batteryStatus
                        text: "Unknown"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                        anchors.baseline: batteryLabel.baseline
                    }
                }

                Separator { 
                    width: parent.width 
                    color: Theme.secondaryHighlightColor 
                    horizontalAlignment: Qt.AlignHCenter 
                }

                // Network
                SectionHeader { text: "Network" }
                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    spacing: Theme.paddingSmall
                    Label {
                        id: networkStatus
                        text: "--"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                    }
                    Label {
                        id: networkIp
                        text: "IP: --"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryColor
                    }
                }

                Separator { 
                    width: parent.width 
                    color: Theme.secondaryHighlightColor 
                    horizontalAlignment: Qt.AlignHCenter 
                }

                // Processes
                SectionHeader { text: "Top Processes" }
                Label {
                    x: Theme.horizontalPageMargin
                    text: "Loading..."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                }
            }
        }
    }

    Python {
        id: python
        Component.onCompleted: {
            addImportPath('/home/defaultuser/apps/system-ninja')
            importModule('backend', function() {
                python.call('backend.get_all', [], function(result) {
                    updateStats(result)
                })
            })
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            python.call('backend.get_all', [], function(result) {
                updateStats(result)
            })
        }
    }

    function updateStats(data) {
        if (!data) return
        app.latestStats = data

        if (data.cpu) {
            cpuLabel.text = data.cpu.pct + "%"
            cpuDetail.text = data.cpu.cores + " cores @ " + data.cpu.freq
            cpuBar.value = data.cpu.pct
        }
        if (data.ram) {
            ramLabel.text = data.ram.used + " / " + data.ram.total + " MB"
            ramBar.value = data.ram.pct
        }
        if (data.storage) {
            storageLabel.text = data.storage.used + " / " + data.storage.total + " GB"
            storageBar.value = data.storage.pct
        }
        if (data.battery) {
            batteryLabel.text = data.battery.capacity + "%"
            batteryStatus.text = data.battery.status
        }
        if (data.network) {
            networkStatus.text = data.network.status
            networkIp.text = "IP: " + data.network.ip
        }
        // Process list removed — Repeater caused ghost text rendering bug
    }
}
