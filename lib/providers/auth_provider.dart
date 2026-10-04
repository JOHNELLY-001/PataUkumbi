import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/api_config.dart';
import '../services/auth_token.dart';

/// Lowest-risk state choice: activates the already-declared `provider`
/// package. Keeps auth logic (loading, token, errors) out of widgets so
/// login/register stop rebuilding gradients and never get stuck.
class AuthProvider extends ChangeNotifier {
  final ApiClient _client;

  AuthProvider({ApiClient? client}) : _client = client ?? ApiClient();

  bool _loading = false;
  bool get loading => _loading;

  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  static const _kTokenKey = 'auth_token';

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kTokenKey);
    AuthTokenStore.set(_token);
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final data = await _client.postJson(
        ApiConfig.login(),
        {'email': email.trim(), 'password': password.trim()},
      );
      await _persistToken(_extractToken(data));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _client.postJson(
        ApiConfig.register(),
        {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim(),
          'contacts': phone.trim(),
          'password': password.trim(),
        },
      );
      // Backend returns 201 without token; user proceeds to login.
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    AuthTokenStore.set(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
    notifyListeners();
  }

  String? _extractToken(dynamic data) {
    if (data is Map) {
      for (final key in ['token', 'access_token', 'accessToken', 'jwt']) {
        final v = data[key];
        if (v is String && v.isNotEmpty) return v;
      }
      final nested = data['data'];
      if (nested is Map) return _extractToken(nested);
    }
    return null;
  }

  Future<void> _persistToken(String? token) async {
    _token = token;
    AuthTokenStore.set(token);
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, token);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
