import 'package:flutter/services.dart';

class AppShortcuts {
  static bool get isControl => HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.controlLeft) ||
      HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.controlRight);

  static bool get isShift => HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.shiftLeft) ||
      HardwareKeyboard.instance.logicalKeysPressed
      .contains(LogicalKeyboardKey.shiftRight);

  static final openItem = LogicalKeyboardKey.enter;
  static final selectAll = LogicalKeyboardKey.keyA;
  static final deselectAll = LogicalKeyboardKey.escape;
  static final toggleSelectDown = LogicalKeyboardKey.insert;
  static final delete = LogicalKeyboardKey.delete;
  static final goUp = LogicalKeyboardKey.backspace;
  static final rename = LogicalKeyboardKey.f2;
}
