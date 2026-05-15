# Sailfish OS App Cover Guidelines

Lessons learned the hard way while building System Ninja's active cover.

## The Golden Rule

**Copy Jolla Calendar.** Their cover works perfectly at all sizes. The pattern is:

```qml
// main.qml
ApplicationWindow {
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
}
```

```qml
// cover/CoverPage.qml
import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    // 1. Action list FIRST (z-order matters)
    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: app.refreshFromCover()
        }
    }

    // 2. Column fills space above action area
    Column {
        x: Theme.paddingLarge
        spacing: Theme.paddingSmall
        width: parent.width - 2 * Theme.paddingLarge
        anchors {
            top: parent.top
            bottom: coverActionArea.top
        }

        // 3. Use fontSizeMode + explicit height for adaptive text
        Label {
            width: parent.width
            height: parent.height * 0.35
            fontSizeMode: Text.VerticalFit
            font.pixelSize: Theme.fontSizeHuge
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
```

## What Works

| Technique | Why It Works |
|-----------|-------------|
| **Separate `cover/CoverPage.qml`** | The compositor handles file-loaded covers better than inline `Component`. Calendar, Messages, and every native app does this. |
| **`CoverBackground` root** | Gets the proper Sailfish ambience background styling. |
| **`CoverActionList` before content** | Ensures actions render at the correct z-order. |
| **`anchors.top` → `coverActionArea.top`** | The Column fills the safe area. Content won't overlap actions or get clipped by them. |
| **`x: Theme.paddingLarge` + explicit width** | More reliable than `anchors.horizontalCenter` for cover positioning. |
| **`fontSizeMode: Text.VerticalFit`** | Font auto-scales to the explicit `height`. Text never overflows its box. |
| **Proportional heights** | `height: parent.height * 0.35` means the element scales with the cover size. |

## What Does NOT Work (qmlscene / on-device builds)

| Technique | Why It Fails |
|-----------|-------------|
| **`allowResize: true`** | The compositor ignores it for qmlscene apps. The cover window stays at `Theme.coverSizeLarge` and gets cropped/clipped. |
| **`scale` or `transform: Scale`** | Causes content to overflow the cover bounds. The compositor clips overflow. |
| **`anchors.centerIn: parent`** | When the compositor crops the cover, centered content gets cut. |
| **`fontSizeMode: Text.Fit` on multi-line text** | Shrinks font to unusable sizes for wrapped text. Use `Text.VerticalFit` on single-line labels with explicit `height` instead. |
| **Huge fixed fonts** | `Theme.fontSizeExtraLarge * 1.5` renders great large but becomes unreadable when the compositor scales the cover bitmap down. |
| **Inline `cover: Component { ... }`** | May not be registered correctly by the compositor. Always use a separate file. |

## How the Compositor Actually Handles Covers

1. Your cover is rendered as a window at `Theme.coverSizeLarge` dimensions.
2. The task switcher displays it via `WindowPixmapItem`.
3. If the aspect ratio matches the cell: shown at **1:1 scale** and **cropped** to the cell bounds.
4. If aspect ratios differ: scaled to fit via `xScale`/`yScale`.
5. The visible crop area is roughly the **center-top** of the cover. Content anchored to `parent.top` survives.

## File Structure

```
project/
├── main.qml
├── cover/
│   └── CoverPage.qml
```

## Exposing App State to the Cover

The cover runs in the same QML engine, so `app.yourProperty` and `app.yourFunction()` are accessible:

```qml
// main.qml
ApplicationWindow {
    id: app
    property var latestStats: ({"cpu":{"pct":0}})

    function refreshFromCover() {
        python.call("backend.get_all", [], function(result) {
            updateStats(result)
        })
    }
}
```

```qml
// cover/CoverPage.qml
Label {
    text: app.latestStats.cpu.pct + "%"
}
```

## Quick Checklist

- [ ] Cover is in `cover/CoverPage.qml`, loaded via `Qt.resolvedUrl()`
- [ ] Root is `CoverBackground`
- [ ] `CoverActionList` is declared before the main content Column
- [ ] Column uses `anchors { top: parent.top; bottom: coverActionArea.top }`
- [ ] Column uses `x: Theme.paddingLarge` and `width: parent.width - 2*Theme.paddingLarge`
- [ ] Labels use `fontSizeMode: Text.VerticalFit` with explicit `height`
- [ ] No `allowResize`, no `scale` transforms, no `anchors.centerIn: parent`
