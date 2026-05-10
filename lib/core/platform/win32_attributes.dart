import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const _fileAttributeHidden = 0x2;
const _fileAttributeSystem = 0x4;
const _invalidFileAttributes = 0xFFFFFFFF;

DynamicLibrary? _kernel32;
int Function(Pointer<Utf16>)? _getFileAttributesW;

DynamicLibrary? _shell32;
int Function(
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
)? _shellExecuteW;

void _ensureKernel32() {
  if (_kernel32 != null) return;
  _kernel32 = DynamicLibrary.open('kernel32.dll');
  _getFileAttributesW = _kernel32!
      .lookupFunction<
        Uint32 Function(Pointer<Utf16>),
        int Function(Pointer<Utf16>)
      >('GetFileAttributesW');
}

void _ensureShell32() {
  if (_shell32 != null) return;
  _shell32 = DynamicLibrary.open('shell32.dll');
  _shellExecuteW = _shell32!
      .lookupFunction<
          IntPtr Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>,
              Pointer<Utf16>, Pointer<Utf16>, Int32),
          int Function(int, Pointer<Utf16>, Pointer<Utf16>, Pointer<Utf16>,
              Pointer<Utf16>, int)>('ShellExecuteW');
}

bool isHiddenOnWindows(String path) {
  if (!Platform.isWindows) return false;
  _ensureKernel32();
  final pathPtr = path.toNativeUtf16();
  try {
    final attrs = _getFileAttributesW!(pathPtr);
    if (attrs == _invalidFileAttributes) return false;
    return (attrs & _fileAttributeHidden) != 0 ||
        (attrs & _fileAttributeSystem) != 0;
  } finally {
    calloc.free(pathPtr);
  }
}

void shellOpenOnWindows(String path) {
  if (!Platform.isWindows) return;
  _ensureShell32();
  final verb = 'open'.toNativeUtf16();
  final file = path.toNativeUtf16();
  try {
    _shellExecuteW!(0, verb, file, nullptr, nullptr, 1);
  } finally {
    calloc.free(verb);
    calloc.free(file);
  }
}
