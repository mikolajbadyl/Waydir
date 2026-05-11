<div align="center">

# Waydir

A fast, keyboard-driven desktop file manager built with Flutter.

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white&style=flat-square)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9+-0175C2?logo=dart&logoColor=white&style=flat-square)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Linux%20%7C%20Windows%20%7C%20macOS-informational?style=flat-square)]()

</div>

![Waydir](docs/screenshots/waydir.png)

---

> Heads up: Waydir is **WIP**. It works, but corners are still being polished. Expect rough edges and breaking changes.

## What is Waydir?

Waydir is the file manager I wanted on my own machine: hands stay on the keyboard, the UI gets out of the way, and opening a 100k-file directory doesn't lock up the window.

It's built on Flutter so the same binary runs on Linux, Windows and macOS from one codebase.

## What works today

- Dual-pane navigation with tabs
- Keyboard-driven nav, selection, and file ops
- Background-isolate directory scanning (no UI jank)
- Copy / move / delete with progress
- Clipboard integration
- Theming and i18n

## Quick start

```bash
git clone https://github.com/mikolajbadyl/waydir.git
cd waydir
flutter pub get
flutter run -d linux   # or -d windows / -d macos
```

Build a release binary:

```bash
flutter build linux    # windows / macos
```

## Contributing

PRs are welcome. Before opening one:

1. `dart format .`
2. `flutter analyze` - must be clean.
3. `flutter test` - must be green.

CI runs the same three on every PR (see `.github/workflows/`). Keep commits focused; small PRs land faster than big ones.

If you're picking up something non-trivial, open an issue first so we can sync on the approach.

## License

[MIT](LICENSE)
