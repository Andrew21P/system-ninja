import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: aboutColumn.height + Theme.paddingLarge

        Column {
            id: aboutColumn
            width: parent.width
            spacing: 0

            PageHeader { title: "About" }

            Item {
                width: parent.width
                height: appIcon.height + Theme.paddingLarge

                Image {
                    id: appIcon
                    anchors {
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: Theme.iconSizeExtraLarge
                    height: Theme.iconSizeExtraLarge
                    source: Qt.resolvedUrl("../app-icon.png")
                    fillMode: Image.PreserveAspectFit
                }
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                text: "System Ninja"
                font.pixelSize: Theme.fontSizeExtraLarge
                color: Theme.highlightColor
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                text: "v1.0 Experimental"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                horizontalAlignment: Text.AlignHCenter
            }

            Item { width: parent.width; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: descCol.height + 2 * Theme.paddingMedium
                color: Theme.rgba(Theme.secondaryColor, 0.06)
                radius: Theme.paddingMedium

                Column {
                    id: descCol
                    anchors {
                        left: parent.left; right: parent.right
                        margins: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: "A lean system monitor for Sailfish OS. Nothing fancy, just the stats you need without the bloat."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: infoCol.height + 2 * Theme.paddingMedium
                color: Theme.rgba(Theme.secondaryColor, 0.06)
                radius: Theme.paddingMedium

                Column {
                    id: infoCol
                    anchors {
                        left: parent.left; right: parent.right
                        margins: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: "Every line was written, tested and debugged directly on a Sony Xperia XA2. No desktop IDE, no emulator, no SDK. Just a phone, a terminal, and a lot of patience."
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        width: parent.width
                        text: "Built in Portugal"
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge }

            Rectangle {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                height: ossCol.height + 2 * Theme.paddingMedium
                color: Theme.rgba(Theme.secondaryColor, 0.06)
                radius: Theme.paddingMedium

                Column {
                    id: ossCol
                    anchors {
                        left: parent.left; right: parent.right
                        margins: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        text: "Open Source"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        width: parent.width
                        text: "MIT licensed. Fork it, break it, improve it."
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.secondaryColor
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    BackgroundItem {
                        width: parent.width
                        height: Theme.itemSizeSmall
                        onClicked: Qt.openUrlExternally("https://github.com/Andrew21P/system-ninja")

                        Label {
                            anchors.centerIn: parent
                            text: "github.com/Andrew21P/system-ninja"
                            font.pixelSize: Theme.fontSizeSmall
                            color: parent.highlighted ? Theme.highlightColor : "#4da6ff"
                        }
                    }
                }
            }

            Item { width: parent.width; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }
}
