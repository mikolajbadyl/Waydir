import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const _fileAttributeHidden = 0x2;
const _fileAttributeSystem = 0x4;
const _invalidFileAttributes = 0xFFFFFFFF;

DynamicLibrary? _kernel32;
int Function(Pointer<Utf16>)? _getFileAttributesW;

void _ensureInitialized() {
  if (_kernel32 != null) return;
  _kernel32 = DynamicLibrary.open('kernel32.dll');
  _getFileAttributesW = _kernel32!
      .lookupFunction<
        Uint32 Function(Pointer<Utf16>),
        int Function(Pointer<Utf16>)
      >('GetFileAttributesW');
}

bool isHiddenOnWindows(String path) {
  if (!Platform.isWindows) return false;
  _ensureInitialized();
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
