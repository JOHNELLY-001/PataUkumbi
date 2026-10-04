import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wishlist store: venue ids persisted locally, synced to every heart icon.
class SavedProvider extends ChangeNotifier {
  static const _key = 'saved_venue_ids';

  final Set<int> _ids = {};
  Set<int> get ids => _ids;
  bool isSaved(int id) => _ids.contains(id);
  int get count => _ids.length;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    _ids
      ..clear()
      ..addAll(list.map(int.tryParse).whereType<int>());
    notifyListeners();
  }

  Future<void> toggle(int id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, _ids.map((e) => e.toString()).toList());
  }
}
