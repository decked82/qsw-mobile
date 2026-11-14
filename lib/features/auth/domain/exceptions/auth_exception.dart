class AuthException implements Exception {
  const AuthException(this.code);

  final String code;

  @override
  String toString() => 'AuthException($code)';
}
