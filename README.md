# System Ninja

Native system monitor for Sailfish OS. Built on-device on a Sony Xperia XA2 with nothing but a terminal and patience.

## What is this?

I've been building Android apps for years - Android Studio, emulators, Gradle, the whole SDK dance. When I got my hands on a Sailfish OS phone, I wanted to try something different: build an app directly on the device itself. No PC, no SDK, no emulator. Just the phone, Python, QML, and a lot of trial and error.

This is my first Sailfish OS project. It's probably not perfect - feel free to open an issue if you spot something weird - but it works and I'm pretty happy with how it turned out.

## Features

- **Live CPU monitoring** - real-time usage with per-core breakdown
- **RAM usage** - used / total with a progress bar
- **Storage stats** - internal storage usage
- **Battery** - capacity %, charging state and temperature
- **Network** - live RX/TX speeds and IP address
- **Load average** - 1m, 5m, 15m
- **Top processes** - most CPU-hungry processes
- **Thermal** - CPU temperature where available
- **Cover page** - CPU bar visible from the task switcher
- **Pull-to-refresh** - native Silica gesture

## Tech

| Layer | Technology |
|-------|------------|
| UI | QML + Sailfish Silica |
| Backend | Python 3 + PyOtherSide |
| Runtime | qmlscene (Qt 5.6) |

## Building

I built this entirely on the phone. If you want to do the same:

1. Install `qmlscene` and `qtchooser`:
   ```bash
   devel-su rpm -ivh qt5-qtdeclarative-qmlscene-*.rpm qtchooser-*.rpm
   ```

2. Clone the repo:
   ```bash
   git clone git@github.com:Andrew21P/system-ninja.git
   ```

3. Copy the desktop file:
   ```bash
   cp system-ninja/system-ninja.desktop ~/.local/share/applications/
   ```

4. Tap the icon in your app grid.

Or just grab the RPM from the releases page.

## Why

Mostly because I could. Also because I wanted to see if a phone can build apps for itself. Turns out it can - root access, Python and QML go a long way.

## License

MIT. Do whatever you want with it.
