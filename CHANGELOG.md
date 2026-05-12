# Changelog

All notable changes to Waydir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Dynamic drive management with real-time detection of connected drives.
- Mount and unmount drives directly from the sidebar.
- Mouse drag selection (lasso) to easily select multiple files.
- Windows support (paths, drives, breadcrumbs, system file filtering, native file opening).

### Changed
- Migrated settings persistence from JSON file to SQLite via Drift.
- Removed `scaled_app` and custom UI scaling system.

### Fixed
- Double title bar on Windows.
- Remove autostart from Windows installer.
- Disable macOS app sandbox to allow full filesystem access.

## [0.1.1] - 2026-05-09

### Fixed
- UI scaling across the app via `scaled_app` integration.

## [0.1.0] - 2026-05-09

### Added
- Initial public release.
- Dual-pane file browsing with tabs.
- Keyboard-driven workflow with custom shortcuts.
- File operations (copy, move, delete) with progress panel and notifications.
- Custom dark theme and custom title bar.
- Settings store with persistent user preferences.

[Unreleased]: https://github.com/mikolajbadyl/waydir/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/mikolajbadyl/waydir/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/mikolajbadyl/waydir/releases/tag/v0.1.0
