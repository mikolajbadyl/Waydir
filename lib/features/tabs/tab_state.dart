import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';
import '../navigation/navigation_store.dart';

class TabState {
  final String id;
  final NavigationStore store;
  late final Computed<String> title;

  TabState({required this.id, required this.store}) {
    title = computed(() {
      final path = store.currentPath.value;
      final name = p.basename(path);
      if (name.isEmpty) return '/';
      return name;
    });
  }
}
