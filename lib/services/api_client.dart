import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_token.dart';

/// Thin wrapper around `package:http` with timeout + consistent errors.
///
/// Keeps network concerns out of widgets so screens stay rebuild-cheap and
/// testable. Backend can later add retry/ETag/auth headers here in one place.
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonBody) headers['Content-Type'] = 'application/json';
    final token = AuthTokenStore.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> getJson(Uri uri) async {
    final sentAuth = AuthTokenStore.token?.isNotEmpty ?? false;
    try {
      final res = await _client
          .get(uri, headers: _headers())
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on ApiException catch (e) {
      await _onAuthError(e, sentAuth);
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> postJson(Uri uri, Map<String, dynamic> body) async {
    final sentAuth = AuthTokenStore.token?.isNotEmpty ?? false;
    try {
      final res = await _client
          .post(
            uri,
            headers: _headers(jsonBody: true),
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on ApiException catch (e) {
      await _onAuthError(e, sentAuth);
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> patchJson(Uri uri, Map<String, dynamic> body) async {
    final sentAuth = AuthTokenStore.token?.isNotEmpty ?? false;
    try {
      final res = await _client
          .patch(
            uri,
            headers: _headers(jsonBody: true),
            body: json.encode(body),
          )
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on ApiException catch (e) {
      await _onAuthError(e, sentAuth);
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// Session expiry: only authed calls can 401-meaningfully; the login
  /// screen's own 400/404s never trigger this.
  Future<void> _onAuthError(ApiException e, bool sentAuth) {
    if (e.statusCode == 401 && sentAuth) {
      return AuthTokenStore.fireAuthFailure();
    }
    return Future.value();
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return json.decode(res.body);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = json.decode(res.body);
      if (body is Map) {
        // Backend historically mixes `message` and `error` keys.
        final m = body['message'];
        final e = body['error'];
        if (m is String && m.isNotEmpty) {
          message = m;
        } else if (e is String && e.isNotEmpty) {
          message = e;
        }
      }
    } catch (_) {
      // Keep generic message when body is not JSON.
    }
    throw ApiException(message, statusCode: res.statusCode);
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}

/// Plain-language auth errors: backend messages are often technical
/// ("Unauthorized", "Validation failed"), so map the cases users hit
/// most to something actionable. Unknown cases keep the raw message.
/// Backend truth (verified): wrong password is 400 "Wrong password",
/// unknown email is 404 "User not found", duplicate register is 400
/// "Email already used", rate limits are 429. There is no 401/409 path
/// on these endpoints — the old mapping never fired.
String friendlyAuthError(ApiException e, {required bool isLogin}) {
  final msg = e.message.toLowerCase();
  if (isLogin && e.statusCode == 400 && msg.contains('wrong password')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (isLogin && e.statusCode == 404) {
    return 'No account found for that email. Try signing up instead.';
  }
  if (!isLogin &&
      e.statusCode == 400 &&
      (msg.contains('already used') || msg.contains('already registered'))) {
    return 'This email is already registered. Try logging in instead.';
  }
  if (e.statusCode == 429) {
    return 'Too many attempts. Please wait a few minutes and try again.';
  }
  if (e.statusCode == 401) {
    return 'Your session expired. Please log in again.';
  }
  if (e.statusCode != null && e.statusCode! >= 500) {
    return 'Our servers are having trouble. Please try again in a moment.';
  }
  return e.message;
}
