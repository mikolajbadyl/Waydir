<div align="center">

# Waydir

**Navigate your files. Your way.**

A fast, keyboard-driven desktop file manager built with Flutter.

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white&style=flat-square)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart&logoColor=white&style=flat-square)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Linux%20%7C%20Windows%20%7C%20macOS-informational?style=flat-square)]()

</div>

![Waydir](docs/screenshots/waydir.png)

---

> **Note:** Waydir is currently a **Work in Progress (WIP)**. Some features are still being built.

## Why Waydir?

Most file managers make you choose: the speed of the terminal or the comfort of a GUI.
Waydir doesn't.

- **Keyboard-first** - navigate, search, and operate without touching the mouse
- **Never stutters** - directory scanning runs in background isolates, even with 100k+ files
- **Cross-platform** - native on Linux, Windows, and macOS

## Features

- ⚡ Lag-free even in directories with 100k+ files (background isolates)
- ⌨️ Full keyboard navigation - never touch the mouse
- 🎨 Themeable, clutter-free UI
- 🔜 SSH/SFTP support
- 🔜 Media preview panel

## Quick Start

```bash
git clone https://github.com/mikolajbadyl/waydir.git
cd waydir
flutter pub get
flutter run -d linux
```

## Build

```bash
flutter build linux
flutter build windows
flutter build macos
```

## License

[MIT](LICENSE)
