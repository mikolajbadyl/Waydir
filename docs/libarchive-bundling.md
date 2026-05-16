# Libarchive Bundling

Waydir treats libarchive as an optional runtime dependency. Source builds must
not require bundled native libraries; archive browsing should degrade cleanly
when libarchive is unavailable.

The runtime loader tries app-local libraries first and system libraries second.
Official release builds can vendor libarchive before packaging.

## Source Builds

Contributors can run the app without libarchive. Archive support is enabled
when the library is available on the host:

```sh
flutter run
flutter test test/core/archive/libarchive_loader_test.dart
```

Linux developers usually need `libarchive13`, `libarchive` or equivalent.
macOS developers can use Homebrew. Windows developers can use vcpkg or MSYS2.

## Linux

For `.deb` and `.rpm`, prefer a package dependency on the distro libarchive
package. For AppImage, copy the shared objects into:

```text
third_party/libarchive/linux/
```

The CMake install step copies `*.so` and `*.so.*` from that folder into the app
bundle `lib/` directory.

```sh
scripts/vendor_libarchive_linux.sh
```

## Windows

Build or install libarchive with vcpkg or MSYS2/UCRT and copy the runtime DLLs
into:

```text
third_party/libarchive/windows/
```

Include `archive.dll` or `libarchive.dll` plus required compression DLLs such
as zlib, lzma, bzip2, zstd, lz4, iconv or crypto libraries, depending on the
chosen build. The CMake install step copies all `*.dll` files next to
`waydir.exe`.

```powershell
scripts\vendor_libarchive_windows.ps1 -SourceDir C:\path\to\libarchive\bin
```

## macOS

Copy `libarchive.dylib` and any non-system dependency dylibs into:

```text
third_party/libarchive/macos/
```

The Xcode build copies these into `Waydir.app/Contents/Frameworks`. Release
builds should ensure the dylibs use install names compatible with
`@executable_path/../Frameworks` or `@rpath`, then codesign the final app.

```sh
scripts/vendor_libarchive_macos.sh
```

## Loader Order

The Dart FFI loader should resolve libarchive in this order:

1. App-local bundled path.
2. Standard system library name.
3. A clear unavailable-backend error.

Expected system names are `libarchive.so.13`, `libarchive.so`,
`libarchive.dylib`, `archive.dll` and `libarchive.dll`.
