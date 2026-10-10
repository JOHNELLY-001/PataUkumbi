/// Process-wide auth token holder (no context needed).
///
/// [AuthProvider] writes here on login/restore/logout; [ApiClient] reads here
/// to attach `Authorization: Bearer` headers. Keeps provider <-> http free of
/// circular imports.
class AuthTokenStore {
  static String? _token;

  static String? get token => _token;
  static void set(String? value) => _token = value;

  /// Fired once per session-expiry wave when an AUTHeD request gets 401.
  /// Wired in main.dart (logout + route to /login). Guarded in ApiClient
  /// so concurrent 401s navigate only once.
  static Future<void> Function()? onAuthFailure;
  static bool _firing = false;

  static Future<void> fireAuthFailure() async {
    if (_firing) return;
    _firing = true;
    try {
      await onAuthFailure?.call();
    } finally {
      _firing = false;
    }
  }
}
