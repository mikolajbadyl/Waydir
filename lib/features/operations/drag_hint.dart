import 'package:signals/signals_flutter.dart';

enum DragMode { copy, move }

class DragHintController {
  static final DragHintController instance = DragHintController._();
  DragHintController._();

  final mode = signal(DragMode.copy);
}
