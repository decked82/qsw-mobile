class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser && other.uid == uid && other.email == email;
  }

  @override
  int get hashCode => Object.hash(uid, email);
}
