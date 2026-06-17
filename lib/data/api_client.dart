import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin client for the Nest API at nestwithin.mrrado.com/api.
///
/// Every call is best-effort: callers treat failures as "stay local/offline",
/// so the app works fully without the backend. Override [base] for local dev.
class ApiClient {
  /// Same-origin on web; absolute (still same host) on mobile.
  static const String base = String.fromEnvironment(
    'NEST_API',
    defaultValue: 'https://nestwithin.mrrado.com/api',
  );

  static const _timeout = Duration(seconds: 12);

  final http.Client _http;
  ApiClient([http.Client? client]) : _http = client ?? http.Client();

  Uri _u(String path) => Uri.parse('$base$path');

  Map<String, String> _headers([String? token]) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<bool> health() async {
    try {
      final r = await _http.get(_u('/health')).timeout(_timeout);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Returns {token, user} on success. Throws [ApiException] on a handled
  /// error (e.g. email taken), or rethrows on network failure.
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String referral,
    required int rating,
    required bool anonymous,
  }) async {
    final r = await _http
        .post(
          _u('/auth/signup'),
          headers: _headers(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'referral': referral,
            'rating': rating,
            'anonymous': anonymous,
          }),
        )
        .timeout(_timeout);
    return _decodeAuth(r);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final r = await _http
        .post(
          _u('/auth/login'),
          headers: _headers(),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);
    return _decodeAuth(r);
  }

  Future<void> requestReset(String email) async {
    await _http
        .post(
          _u('/auth/request-reset'),
          headers: _headers(),
          body: jsonEncode({'email': email}),
        )
        .timeout(_timeout);
  }

  Future<void> patchMe(String token, {bool? anonymous, String? name}) async {
    final body = <String, dynamic>{};
    if (anonymous != null) body['anonymous'] = anonymous;
    if (name != null) body['name'] = name;
    await _http
        .patch(_u('/me'), headers: _headers(token), body: jsonEncode(body))
        .timeout(_timeout);
  }

  Future<void> logActivity(
    String token, {
    required String practiceId,
    required String kind,
    required int seconds,
  }) async {
    await _http
        .post(
          _u('/activity'),
          headers: _headers(token),
          body: jsonEncode({
            'practiceId': practiceId,
            'kind': kind,
            'seconds': seconds,
          }),
        )
        .timeout(_timeout);
  }

  Future<List<({String practiceId, int count})>> popular() async {
    final r = await _http.get(_u('/stats/popular')).timeout(_timeout);
    final list = (jsonDecode(r.body)['activities'] as List).cast<Map>();
    return [
      for (final m in list)
        (practiceId: m['practiceId'] as String, count: m['count'] as int),
    ];
  }

  Future<List<ApiActiveUser>> activeUsers() async {
    final r = await _http.get(_u('/stats/active-users')).timeout(_timeout);
    final list = (jsonDecode(r.body)['users'] as List).cast<Map>();
    return [for (final m in list) ApiActiveUser.fromJson(m)];
  }

  Map<String, dynamic> _decodeAuth(http.Response r) {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode == 200) return body;
    throw ApiException(body['error'] as String? ?? 'error', r.statusCode);
  }
}

class ApiActiveUser {
  final String display;
  final int practices;
  final String favoritePracticeId;
  final bool anonymous;
  ApiActiveUser(
    this.display,
    this.practices,
    this.favoritePracticeId,
    this.anonymous,
  );

  factory ApiActiveUser.fromJson(Map j) => ApiActiveUser(
    j['display'] as String,
    j['practices'] as int,
    j['favoritePracticeId'] as String? ?? 'box-breath',
    j['anonymous'] as bool? ?? false,
  );
}

class ApiException implements Exception {
  final String code;
  final int status;
  ApiException(this.code, this.status);

  /// A friendly message for the few errors worth surfacing.
  String get message => switch (code) {
    'email_taken' => 'That email already has an account. Try signing in.',
    'bad_credentials' => 'Email or password is incorrect.',
    'invalid_email' => 'Please enter a valid email.',
    'weak_password' => 'Password must be at least 8 characters.',
    'name_required' => 'Please add your name.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'ApiException($code, $status)';
}
