import 'package:shared_preferences/shared_preferences.dart';

/// Recent search queries (max 6, most-recent-first, deduped).
abstract final class SearchHistory {
  static const _key = 'recent_searches_v1';
  static const _max = 6;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<List<String>> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return load();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.remove(q);
    list.insert(0, q);
    await prefs.setStringList(_key, list.take(_max).toList());
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Recently viewed venue ids (max 10, most-recent-first).
abstract final class ViewedHistory {
  static const _key = 'recently_viewed_v1';
  static const _max = 10;

  static Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? const [];
    return list.map(int.tryParse).whereType<int>().toList();
  }

  static Future<void> record(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.remove(id.toString());
    list.insert(0, id.toString());
    await prefs.setStringList(_key, list.take(_max).toList());
  }
}
