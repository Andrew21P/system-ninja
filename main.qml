import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5

ApplicationWindow {
    id: app

    property var latestStats: ({
        "cpu": {"pct": 0, "per_core": [], "cores": 0, "freq": "--"},
        "ram": {"pct": 0, "used": 0, "total": 0},
        "storage": {"pct": 0, "used": 0, "total": 0},
        "battery": {"capacity": 0, "status": "Unknown", "temp": 0},
        "network": {"iface": "None", "rx_speed": 0, "tx_speed": 0, "ip": "--"},
        "thermal": {"cpu_temp": 0},
        "load": [0, 0, 0],
        "processes": [],
        "history": {"cpu": [], "ram": []},
        "system": {"model": "Device", "processor": "--", "kernel": "--", "uptime": "--", "os": "Sailfish OS"}
    })

    property int tick: 0

    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    function refreshFromCover() {
        python.call("backend.get_all", [], function(result) {
            if (result) {
                app.latestStats = result
                app.tick++
            }
        })
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B/s"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s"
        return (bytes / 1048576).toFixed(1) + " MB/s"
    }

    function tempColor(temp) {
        if (temp > 70) return "#ff4d4d"
        if (temp > 55) return "#ffaa00"
        if (temp > 40) return "#ffcc00"
        return "#00cc66"
    }

    function barColor(pct) {
        return pct > 80 ? "#ff4d4d" : pct > 50 ? "#ffaa00" : "#00cc66"
    }

    initialPage: Component {
        Page {
            id: mainPage
            SilicaFlickable {
            anchors.fill: parent
            contentHeight: contentColumn.height + Theme.paddingLarge

            PullDownMenu {
                MenuItem {
                    text: "Refresh"
                    onClicked: {
                        python.call('backend.get_all', [], function(result) {
                            if (result) {
                                app.latestStats = result
                                app.tick++
                            }
                        })
                    }
                }
            }

            Column {
                id: contentColumn
                width: parent.width
                spacing: 0

                PageHeader { title: "System Ninja" }

                // ═══════════════════════════════════════════
                // SYSTEM INFO CARD
                // ═══════════════════════════════════════════
                Item {
                    width: parent.width
                    height: sysInfoCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.06)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: sysInfoCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Label {
                            width: parent.width
                            text: app.latestStats.system.model
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.highlightColor
                            font.bold: true
                            wrapMode: Text.Wrap
                        }
                        Label {
                            width: parent.width
                            text: app.latestStats.system.processor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            wrapMode: Text.Wrap
                        }
                        Label {
                            width: parent.width
                            text: app.latestStats.system.os + " · " + app.latestStats.system.kernel
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            truncationMode: TruncationMode.Fade
                        }
                        Label {
                            width: parent.width
                            text: "Uptime: " + app.latestStats.system.uptime
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // CPU SECTION
                // ═══════════════════════════════════════════
                SectionHeader { text: "CPU" }

                Item {
                    width: parent.width
                    height: cpuSectionCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: cpuSectionCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Row {
                            width: parent.width
                            Label {
                                id: cpuBigLabel
                                text: (app.latestStats.cpu.pct || 0) + "%"
                                font.pixelSize: Theme.fontSizeHuge
                                font.bold: true
                                color: barColor(app.latestStats.cpu.pct || 0)
                                Behavior on color { ColorAnimation { duration: 500 } }
                                SequentialAnimation on scale {
                                    loops: Animation.Infinite
                                    running: (app.latestStats.cpu.pct || 0) > 80
                                    NumberAnimation { to: 1.04; duration: 600; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutQuad }
                                }
                            }
                            Item { width: Theme.paddingMedium; height: 1 }
                            Label {
                                anchors.baseline: cpuBigLabel.baseline
                                text: (app.latestStats.cpu.cores || 0) + " cores @ " + (app.latestStats.cpu.freq || "--")
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                        }

                        // Main CPU bar
                        Item {
                            width: parent.width
                            height: Theme.paddingMedium * 1.5
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.rgba(Theme.secondaryColor, 0.15)
                                radius: height / 2
                            }
                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                color: barColor(app.latestStats.cpu.pct || 0)
                                width: parent.width * (app.latestStats.cpu.pct || 0) / 100
                                Behavior on width {
                                    SmoothedAnimation { duration: 1000; easing.type: Easing.OutCubic }
                                }
                                Behavior on color { ColorAnimation { duration: 500 } }
                            }
                        }

                        // CPU sparkline
                        Canvas {
                            id: cpuSparkline
                            width: parent.width
                            height: Theme.paddingLarge * 3
                            property int paintTrigger: app.tick
                            onPaintTriggerChanged: requestPaint()
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                var data = app.latestStats.history ? app.latestStats.history.cpu : []
                                if (data.length < 2) return
                                ctx.strokeStyle = Theme.highlightColor
                                ctx.lineWidth = 2
                                ctx.lineJoin = "round"
                                ctx.beginPath()
                                var step = width / (Math.max(data.length, 2) - 1)
                                for (var i = 0; i < data.length; i++) {
                                    var x = i * step
                                    var y = height - (data[i] / 100) * height
                                    if (i === 0) ctx.moveTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.stroke()
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // RAM SECTION
                // ═══════════════════════════════════════════
                SectionHeader { text: "Memory" }

                Item {
                    width: parent.width
                    height: ramSectionCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: ramSectionCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Row {
                            width: parent.width
                            Label {
                                id: ramBigLabel
                                text: (app.latestStats.ram.pct || 0) + "%"
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: "#4da6ff"
                            }
                            Item { width: Theme.paddingMedium; height: 1 }
                            Label {
                                anchors.baseline: ramBigLabel.baseline
                                text: (app.latestStats.ram.used || 0) + " / " + (app.latestStats.ram.total || 0) + " MB"
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                        }

                        Item {
                            width: parent.width
                            height: Theme.paddingMedium * 1.5
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.rgba(Theme.secondaryColor, 0.15)
                                radius: height / 2
                            }
                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                color: "#4da6ff"
                                width: parent.width * (app.latestStats.ram.pct || 0) / 100
                                Behavior on width {
                                    SmoothedAnimation { duration: 1000; easing.type: Easing.OutCubic }
                                }
                            }
                        }


                    }
                }

                // ═══════════════════════════════════════════
                // STORAGE SECTION
                // ═══════════════════════════════════════════
                SectionHeader { text: "Storage" }

                Item {
                    width: parent.width
                    height: storageCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: storageCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Row {
                            width: parent.width
                            Label {
                                id: storageBigLabel
                                text: (app.latestStats.storage.pct || 0) + "%"
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: "#ffaa00"
                            }
                            Item { width: Theme.paddingMedium; height: 1 }
                            Label {
                                anchors.baseline: storageBigLabel.baseline
                                text: (app.latestStats.storage.used || 0) + " / " + (app.latestStats.storage.total || 0) + " GB"
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                        }

                        Item {
                            width: parent.width
                            height: Theme.paddingMedium * 1.5
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.rgba(Theme.secondaryColor, 0.15)
                                radius: height / 2
                            }
                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                color: "#ffaa00"
                                width: parent.width * (app.latestStats.storage.pct || 0) / 100
                                Behavior on width {
                                    SmoothedAnimation { duration: 1000; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // BATTERY SECTION
                // ═══════════════════════════════════════════
                SectionHeader { text: "Battery" }

                Item {
                    width: parent.width
                    height: batteryCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: batteryCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Row {
                            width: parent.width
                            Label {
                                id: batteryBigLabel
                                text: {
                                    var cap = app.latestStats.battery.capacity || 0
                                    var status = app.latestStats.battery.status || "Unknown"
                                    return (status === "Charging" ? "⚡ " : "") + cap + "%"
                                }
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: {
                                    var cap = app.latestStats.battery.capacity || 0
                                    return cap < 20 ? "#ff4d4d" : cap < 50 ? "#ffaa00" : "#00cc66"
                                }
                            }
                            Item { width: Theme.paddingMedium; height: 1 }
                            Label {
                                anchors.baseline: batteryBigLabel.baseline
                                text: app.latestStats.battery.status || "Unknown"
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.secondaryColor
                            }
                        }

                        Item {
                            width: parent.width
                            height: Theme.paddingMedium * 1.5
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.rgba(Theme.secondaryColor, 0.15)
                                radius: height / 2
                            }
                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                color: {
                                    var cap = app.latestStats.battery.capacity || 0
                                    return cap < 20 ? "#ff4d4d" : cap < 50 ? "#ffaa00" : "#00cc66"
                                }
                                width: parent.width * (app.latestStats.battery.capacity || 0) / 100
                                Behavior on width {
                                    SmoothedAnimation { duration: 1000; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // NETWORK SECTION
                // ═══════════════════════════════════════════
                SectionHeader { text: "Network" }

                Item {
                    width: parent.width
                    height: netCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: netCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Label {
                            text: (app.latestStats.network.iface || "None") + " · " + (app.latestStats.network.ip || "--")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            truncationMode: TruncationMode.Fade
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.paddingLarge
                            Label {
                                text: "↓ " + formatBytes(app.latestStats.network.rx_speed || 0)
                                font.pixelSize: Theme.fontSizeSmall
                                color: "#00ccff"
                                font.bold: true
                            }
                            Label {
                                text: "↑ " + formatBytes(app.latestStats.network.tx_speed || 0)
                                font.pixelSize: Theme.fontSizeSmall
                                color: "#ff66cc"
                                font.bold: true
                            }
                        }

                        // Network activity visualization
                        Row {
                            width: parent.width
                            spacing: Theme.paddingSmall
                            Repeater {
                                model: 8
                                delegate: Rectangle {
                                    width: (parent.width - 7 * parent.spacing) / 8
                                    height: Theme.paddingLarge * 1.5
                                    color: Theme.rgba(Theme.secondaryColor, 0.1)
                                    radius: Theme.paddingSmall
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: {
                                            var rx = app.latestStats.network.rx_speed || 0
                                            var tx = app.latestStats.network.tx_speed || 0
                                            var maxSpd = Math.max(rx, tx, 1)
                                            var norm = Math.min(maxSpd / 1048576, 1)
                                            return parent.height * norm * (0.15 + 0.85 * (index + 1) / 8)
                                        }
                                        radius: Theme.paddingSmall
                                        color: index < 4 ? "#00ccff" : "#ff66cc"
                                        Behavior on height {
                                            SmoothedAnimation { duration: 800 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // THERMAL SECTION
                // ═══════════════════════════════════════════
                SectionHeader { text: "Thermal" }

                Item {
                    width: parent.width
                    height: thermalCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Column {
                        id: thermalCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingSmall

                        Label {
                            text: (app.latestStats.thermal.cpu_temp || 0) + "°C"
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: tempColor(app.latestStats.thermal.cpu_temp || 0)
                        }

                        Item {
                            width: parent.width
                            height: Theme.paddingMedium * 1.5
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.rgba(Theme.secondaryColor, 0.15)
                                radius: height / 2
                            }
                            Rectangle {
                                height: parent.height
                                radius: height / 2
                                color: tempColor(app.latestStats.thermal.cpu_temp || 0)
                                width: parent.width * Math.min((app.latestStats.thermal.cpu_temp || 0) / 100, 1)
                                Behavior on width {
                                    SmoothedAnimation { duration: 1000; easing.type: Easing.OutCubic }
                                }
                                Behavior on color { ColorAnimation { duration: 500 } }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // LOAD AVERAGE
                // ═══════════════════════════════════════════
                SectionHeader { text: "Load Average" }

                Item {
                    width: parent.width
                    height: loadCol.height + 2 * Theme.paddingMedium

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.horizontalPageMargin
                        anchors.rightMargin: Theme.horizontalPageMargin
                        color: Theme.rgba(Theme.secondaryColor, 0.04)
                        radius: Theme.paddingMedium
                    }

                    Row {
                        id: loadCol
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin + Theme.paddingMedium
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Theme.paddingLarge

                        Repeater {
                            model: app.latestStats.load || [0, 0, 0]
                            delegate: Column {
                                Label {
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: modelData > 2 ? "#ff4d4d" : modelData > 1 ? "#ffaa00" : Theme.highlightColor
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Label {
                                    text: index === 0 ? "1m" : index === 1 ? "5m" : "15m"
                                    font.pixelSize: Theme.fontSizeTiny
                                    color: Theme.secondaryColor
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }

                // ═══════════════════════════════════════════
                // TOP PROCESSES
                // ═══════════════════════════════════════════
                SectionHeader { text: "Top Processes" }

                Item {
                    width: parent.width
                    height: procList.contentHeight + Theme.paddingMedium

                    ListView {
                        id: procList
                        anchors {
                            left: parent.left; right: parent.right
                            margins: Theme.horizontalPageMargin
                        }
                        height: contentHeight
                        interactive: false
                        model: app.latestStats.processes || []

                        header: Row {
                            width: parent.width
                            Label {
                                text: "Process"
                                width: parent.width * 0.5
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                                font.bold: true
                            }
                            Label {
                                text: "CPU"
                                width: parent.width * 0.25
                                horizontalAlignment: Text.AlignRight
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                                font.bold: true
                            }
                            Label {
                                text: "MEM"
                                width: parent.width * 0.25
                                horizontalAlignment: Text.AlignRight
                                font.pixelSize: Theme.fontSizeTiny
                                color: Theme.secondaryColor
                                font.bold: true
                            }
                        }

                        delegate: BackgroundItem {
                            width: parent.width
                            height: Theme.itemSizeSmall
                            Row {
                                anchors.fill: parent
                                Label {
                                    text: modelData.name || ""
                                    width: parent.width * 0.5
                                    truncationMode: TruncationMode.Fade
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                                Label {
                                    text: (modelData.cpu_pct || 0) + "%"
                                    width: parent.width * 0.25
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.secondaryColor
                                }
                                Label {
                                    text: (modelData.mem_pct || 0) + "%"
                                    width: parent.width * 0.25
                                    horizontalAlignment: Text.AlignRight
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.secondaryColor
                                }
                            }
                        }
                    }
                }

                Item { height: Theme.paddingLarge; width: parent.width }
            }

            VerticalScrollDecorator {}
        }
    }
}

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'))
            importModule('backend', function() {
                python.call('backend.get_all', [], function(result) {
                    if (result) {
                        app.latestStats = result
                        app.tick++
                    }
                })
            })
        }
        onError: console.log('Python error: ' + traceback)
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            python.call('backend.get_all', [], function(result) {
                if (result) {
                    app.latestStats = result
                    app.tick++
                }
            })
        }
    }
}
