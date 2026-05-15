import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: app.refreshFromCover()
        }
    }

    Column {
        x: Theme.paddingLarge
        spacing: Theme.paddingSmall
        width: parent.width - 2 * Theme.paddingLarge
        anchors {
            top: parent.top
            bottom: coverActionArea.top
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.VerticalFit
            height: parent.height * 0.35
            text: (app.latestStats.cpu ? app.latestStats.cpu.pct : "0") + "%"
            color: {
                var pct = app.latestStats.cpu ? app.latestStats.cpu.pct : 0
                return pct > 80 ? "#ff4d4d" : pct > 50 ? "#ffaa00" : Theme.highlightColor
            }
            font.pixelSize: Theme.fontSizeHuge
            font.bold: true
        }

        Rectangle {
            width: parent.width
            height: parent.height * 0.1
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

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.VerticalFit
            height: parent.height * 0.25
            text: "RAM " + (app.latestStats.ram ? app.latestStats.ram.pct : "0") +
                  "%   BAT " + (app.latestStats.battery ? app.latestStats.battery.capacity : "0") + "%"
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
