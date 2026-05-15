import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5

ApplicationWindow {
    id: app
    
    property var latestStats: ({"cpu":{"pct":0},"ram":{"pct":0},"battery":{"capacity":0}})

    cover: Component {
        Cover {
            allowResize: true
            transparent: true

            Column {
                anchors.fill: parent
                anchors.margins: (size === Cover.Small) ? Theme.paddingSmall : Theme.paddingMedium
                spacing: (size === Cover.Small) ? Theme.paddingSmall : Theme.paddingSmall

                // Title — only in large mode
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "System Ninja"
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeSmall
                    visible: size !== Cover.Small
                }

                // CPU — the hero stat
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (app.latestStats.cpu ? app.latestStats.cpu.pct : "0") + "%"
                    color: {
                        var pct = app.latestStats.cpu ? app.latestStats.cpu.pct : 0
                        return pct > 80 ? "#ff4d4d" : pct > 50 ? "#ffaa00" : Theme.highlightColor
                    }
                    font.pixelSize: (size === Cover.Small) ? Theme.fontSizeExtraLarge : Theme.fontSizeExtraLarge * 1.6
                    font.bold: true
                }

                // CPU label — hidden in small
                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "CPU"
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeTiny
                    visible: size !== Cover.Small
                }

                // CPU visual bar
                Rectangle {
                    width: parent.width
                    height: (size === Cover.Small) ? Theme.paddingSmall : Theme.paddingMedium
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

                // RAM row — only large
                Row {
                    width: parent.width
                    visible: size !== Cover.Small
                    spacing: Theme.paddingSmall

                    Label {
                        text: "RAM"
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeTiny
                        width: parent.width * 0.28
                    }
                    Rectangle {
                        width: parent.width * 0.72
                        height: Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.rgba(Theme.secondaryColor, 0.15)
                        radius: height / 2

                        Rectangle {
                            width: parent.width * (app.latestStats.ram ? app.latestStats.ram.pct : 0) / 100
                            height: parent.height
                            radius: height / 2
                            color: {
                                var pct = app.latestStats.ram ? app.latestStats.ram.pct : 0
                                return pct > 80 ? "#ff4d4d" : pct > 50 ? "#ffaa00" : "#00cc66"
                            }
                        }
                    }
                }

                // Battery row — only large
                Row {
                    width: parent.width
                    visible: size !== Cover.Small
                    spacing: Theme.paddingSmall

                    Label {
                        text: "BAT"
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeTiny
                        width: parent.width * 0.28
                    }
                    Rectangle {
                        width: parent.width * 0.72
                        height: Theme.paddingSmall
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.rgba(Theme.secondaryColor, 0.15)
                        radius: height / 2

                        Rectangle {
                            width: parent.width * (app.latestStats.battery ? app.latestStats.battery.capacity : 0) / 100
                            height: parent.height
                            radius: height / 2
                            color: {
                                var pct = app.latestStats.battery ? app.latestStats.battery.capacity : 0
                                return pct < 20 ? "#ff4d4d" : pct < 50 ? "#ffaa00" : "#00cc66"
                            }
                        }
                    }
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
