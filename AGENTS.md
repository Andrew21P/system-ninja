# Sailfish OS Native App Development Guide

> **READ THIS FIRST** before attempting to build any native app on this device.
> This document captures everything learned from building the System Ninja app.

## Device Context

- **Device**: Sony Xperia XA2 (h3113)
- **OS**: Sailfish OS 5.0.0.72, armv7hl
- **Compositor**: Wayland (lipstick), pure Wayland — **NO XWayland**
- **Python**: 3.13.1 at `/home/defaultuser/local/python/bin/python3`
- **Qt/QML**: qt5-qtdeclarative available, PyOtherSide QML plugin installed
- **Package Manager**: `pkcon`/`PackageKit` is BROKEN (glib 2GB allocation crash); use `rpm -ivh` directly

## What Works vs. What Doesn't

| Approach | Works? | Notes |
|----------|--------|-------|
| Tkinter | ❌ NO | No XWayland. Tkinter is X11-only. Will load infinitely then crash. |
| Web app (browser) | ✅ Yes | Flask/server + browser works but is NOT "native". User sees browser chrome. |
| QML + Silica | ✅ YES | The proper native approach. Uses Jolla's Silica QML framework. |
| PyQt5/PySide2 | ❌ No | Not installed. Compiling on armv7hl takes hours and likely fails. |
| SDL2 | ⚠️ Partial | Libraries exist but no Python bindings. Would need C app. |
| GTK | ❌ No | Not available. |

## The Native Stack

The correct native app stack for Sailfish OS is:

```
QML frontend (Silica components)
    ↓
PyOtherSide QML plugin (io.thp.pyotherside 1.5)
    ↓
Python backend
    ↓
qmlscene launcher
```

### Key Components

1. **qmlscene** — QML runtime. Installed via `qt5-qtdeclarative-qmlscene` RPM.
   - Requires `QT_SELECT=5` environment variable or it fails with "could not find a Qt installation"
   - Needs `qtchooser` dependency

2. **Silica** — Jolla's proprietary QML module (`Sailfish.Silica 1.0`)
   - Available at `/usr/lib/qt5/qml/Sailfish/Silica/`
   - Provides native look/feel: PageHeader, PullDownMenu, ProgressBar, etc.

3. **PyOtherSide** — Python-QML bridge
   - Available at `/usr/lib/qt5/qml/io/thp/pyotherside/`
   - Allows QML to call Python functions and get results via callbacks

## App Structure

```
/home/defaultuser/apps/<app-name>/
├── main.qml          # QML frontend
├── backend.py        # Python backend (optional)
└── launch.sh         # Launcher script

/home/defaultuser/.local/share/applications/<app-name>.desktop
```

### launcher script (`launch.sh`)

```bash
#!/bin/bash
export QT_SELECT=5
exec qmlscene /home/defaultuser/apps/<app-name>/main.qml
```

### desktop file

```ini
[Desktop Entry]
Type=Application
Name=My App
Icon=icon-launcher-settings
Exec=/home/defaultuser/apps/<app-name>/launch.sh
Terminal=false
Categories=System;Utility;
```

**CRITICAL**: Do NOT set `X-Nemo-Application-Type=silica-qt5` unless you have a compiled binary.
If you set it on a shell script, the system wraps it with `invoker` + `sailjail`, which conflicts
with `qmlscene` and causes infinite load → crash.

## QML Architecture Rules

### 1. PageHeader goes INSIDE the SilicaFlickable

**WRONG** — causes layout breakage:
```qml
Page {
    PageHeader { title: "My App" }
    SilicaFlickable { anchors.fill: parent }
}
```

**CORRECT** — header scrolls with content, pull-down works properly:
```qml
Page {
    SilicaFlickable {
        anchors.fill: parent
        Column {
            width: parent.width
            PageHeader { title: "My App" }
            // ... rest of content
        }
    }
}
```

### 2. PullDownMenu goes INSIDE the SilicaFlickable

```qml
SilicaFlickable {
    anchors.fill: parent
    
    PullDownMenu {
        MenuItem {
            text: "Refresh"
            onClicked: { /* ... */ }
        }
    }
    
    Column { /* content */ }
}
```

When `PageHeader` is a sibling of `SilicaFlickable` (outside it), `PullDownMenu` throws
`TypeError: Cannot read property 'contentY' of null` and may crash on device.

### 3. Don't use Repeater for dynamic lists without careful testing

The `Repeater` inside a `Column` can cause ghost text to appear at wrong positions
(like process names leaking to the top-left corner). If you need a process list or
similar dynamic content, prefer a static `Label` that updates its text, or use a
`ListView` with proper delegates.

**Safer pattern for simple lists:**
```qml
Column {
    Repeater {
        model: 5
        delegate: Row {
            // Risky — can cause ghost text
        }
    }
}
```

**Safer pattern:**
```qml
Label {
    text: pythonProcessList  // Single label, text updated from Python
}
```

### 4. Background is handled by Sailfish

Do NOT add a `Rectangle { color: "#000000"; anchors.fill: parent; z: -1 }` behind
your content. Sailfish provides the proper ambience-aware background automatically.
Adding a black rectangle breaks theming and looks wrong.

### 5. No `anchors.fill: parent` on SilicaFlickable when PageHeader is outside

If you must put PageHeader outside (not recommended), use:
```qml
anchors.top: header.bottom
anchors.left: parent.left
anchors.right: parent.right
anchors.bottom: parent.bottom
```

## PyOtherSide Integration

```qml
import io.thp.pyotherside 1.5

Python {
    id: python
    Component.onCompleted: {
        addImportPath('/home/defaultuser/apps/<app-name>')
        importModule('backend', function() {
            python.call('backend.get_all', [], function(result) {
                // Update UI with result
            })
        })
    }
}
```

Python backend (`backend.py`):
```python
def get_all():
    return {
        "cpu": {"pct": 42, "cores": 8, "freq": "1400MHz"},
        "ram": {"used": 1024, "total": 3072, "pct": 33},
        # ... etc
    }
```

## Debugging Tips

### App won't open from app grid (infinite load → crash)

1. **Check desktop file** — remove `X-Nemo-Application-Type=silica-qt5` for qmlscene apps
2. **Clear launcher cache** — restart lipstick:
   ```bash
   killall lipstick  # auto-restarts via systemd
   ```
3. **Kill stale processes**:
   ```bash
   killall qmlscene
   ```
4. **Test from terminal**:
   ```bash
   cd /home/defaultuser/apps/<app-name>
   QT_SELECT=5 qmlscene main.qml
   ```

### Ghost text / visual artifacts

- `Repeater` inside `Column` is a common culprit — replace with static labels
- `PageHeader` outside `SilicaFlickable` causes overlap and pull-down crashes
- Missing `description: ""` on `PageHeader` can show placeholder text in some Silica versions

### Screenshots for debugging

Framebuffer (`/dev/fb0`) is **useless** on GPU-composited devices. Use Qt's built-in grab:

```qml
Timer {
    interval: 1500
    running: true
    repeat: false
    onTriggered: {
        page.grabToImage(function(result) {
            result.saveToFile("/home/defaultuser/Pictures/Screenshots/debug.png")
        })
    }
}
```

This captures the app content (not system UI) and reveals layout issues.

## Installing qmlscene

If `qmlscene` is missing:

```bash
# Download from Jolla repos
cd /tmp
curl -LO "https://releases.jolla.com/releases/5.0.0.72/jolla/armv7hl/oss/armv7hl/qtchooser-26-1.6.3.jolla.armv7hl.rpm"
curl -LO "https://releases.jolla.com/releases/5.0.0.72/jolla/armv7hl/oss/armv7hl/qt5-qtdeclarative-qmlscene-5.6.3+git25-1.8.2.jolla.armv7hl.rpm"

# Install as root
devel-su rpm -ivh qtchooser-26-1.6.3.jolla.armv7hl.rpm qt5-qtdeclarative-qmlscene-5.6.3+git25-1.8.2.jolla.armv7hl.rpm
```

## File Locations Reference

| Purpose | Path |
|---------|------|
| App code | `/home/defaultuser/apps/<name>/` |
| Desktop file | `/home/defaultuser/.local/share/applications/<name>.desktop` |
| User screenshots | `/home/defaultuser/Pictures/Screenshots/` |
| Silica QML | `/usr/lib/qt5/qml/Sailfish/Silica/` |
| PyOtherSide plugin | `/usr/lib/qt5/qml/io/thp/pyotherside/` |
| Qt5 binaries | `/usr/lib/qt5/bin/` (qmlscene lives here) |
| Jolla repos | `https://releases.jolla.com/releases/5.0.0.72/jolla/armv7hl/` |

## App Covers (Active Covers)

See **`COVERS.md`** in the project root for the complete, battle-tested cover guide.

Quick summary:
- Always use a **separate `cover/CoverPage.qml`** loaded via `Qt.resolvedUrl()`
- Root must be **`CoverBackground`** (not `Cover` with `transparent`)
- Place **`CoverActionList` BEFORE content** in the file
- Anchor Column: `top: parent.top` → `bottom: coverActionArea.top`
- Use **`fontSizeMode: Text.VerticalFit`** with explicit `height` for adaptive text
- **Do NOT use `allowResize`** with qmlscene apps — the compositor ignores it and crops
- **Do NOT use `scale` transforms** — causes overflow and clipping

Native apps like Jolla Calendar use this exact pattern. Copy them.

## TL;DR Checklist for New Apps

- [ ] Use QML + Silica, not tkinter or web
- [ ] Put `PageHeader` INSIDE `SilicaFlickable` content
- [ ] Put `PullDownMenu` INSIDE `SilicaFlickable`
- [ ] Launcher script sets `QT_SELECT=5`
- [ ] Desktop file does NOT have `X-Nemo-Application-Type=silica-qt5` for qmlscene apps
- [ ] Avoid `Repeater` in `Column` — use static labels or `ListView`
- [ ] Don't add manual black backgrounds
- [ ] Cover lives in `cover/CoverPage.qml`, referenced via `Qt.resolvedUrl()`
- [ ] Test from terminal with `QT_SELECT=5 qmlscene main.qml` first
- [ ] If app grid is wonky, `killall lipstick` to refresh
