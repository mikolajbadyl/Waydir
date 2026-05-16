# Libarchive Runtime Libraries

Waydir loads libarchive at runtime for archive browsing and extraction.
Platform builds copy files from these folders into the app bundle when they are
present:

- `linux/`: `*.so`, `*.so.*` copied to the Flutter bundle `lib/` directory.
- `windows/`: `*.dll` copied next to `waydir.exe`.
- `macos/`: `*.dylib` copied to `Waydir.app/Contents/Frameworks`.

Keep these folders empty in source control unless a release process explicitly
vendors binaries. CI can populate them before packaging with the scripts in
`scripts/`.

Expected runtime names:

- Linux: `libarchive.so.13` or `libarchive.so`
- Windows: `archive.dll` or `libarchive.dll`
- macOS: `libarchive.dylib`

Suggested sources:

- Linux distribution packages for `.deb`/`.rpm`, or copied shared objects for
  AppImage.
- Homebrew or a project-controlled build for macOS `.dylib`.
- vcpkg or MSYS2/UCRT for Windows DLLs and their compression dependencies.
