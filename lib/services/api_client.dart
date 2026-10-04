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
    try {
      final res = await _client
          .get(uri, headers: _headers())
          .timeout(ApiConfig.timeout);
      return _decode(res);
    } on TimeoutException {
      throw const ApiException('Request timed out. Check your connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> postJson(Uri uri, Map<String, dynamic> body) async {
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
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return json.decode(res.body);
    }
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = json.decode(res.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
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

  @override
  String toString() => message;
}
