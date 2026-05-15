# Changelog

## 1.0.1 - 2026-05-15

### Fixed
- Added missing RPM dependencies (`qt5-qtdeclarative-qmlscene`, `qtchooser`) so the app auto-installs the QML runtime on fresh devices. Previously `qmlscene: not found` would occur on phones where it wasn't pre-installed (e.g., Xperia 10 III).

## 1.0.0 - 2026-05-14

### Added
- Initial release: system monitoring dashboard for Sailfish OS.
- Live CPU, RAM, storage, battery, network, thermal stats.
- Process list with kill action.
- Active cover with live stats.
