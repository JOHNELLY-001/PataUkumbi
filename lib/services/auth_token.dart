/// Process-wide auth token holder (no context needed).
///
/// [AuthProvider] writes here on login/restore/logout; [ApiClient] reads here
/// to attach `Authorization: Bearer` headers. Keeps provider <-> http free of
/// circular imports.
class AuthTokenStore {
  static String? _token;

  static String? get token => _token;
  static void set(String? value) => _token = value;
}
