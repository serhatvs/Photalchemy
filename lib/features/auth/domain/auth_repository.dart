import 'dart:async';

/// Authenticated user representation decoupled from Firebase SDK.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isAnonymous,
  });

  final String id;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          isAnonymous == other.isAnonymous;

  @override
  int get hashCode => Object.hash(id, email, displayName, isAnonymous);

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, isAnonymous: $isAnonymous)';
}

/// Abstract contract for user authentication.
///
/// Implemented by FirebaseAuthRepository (backend) and MockAuthRepository (test/preview).
abstract class AuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> signInAnonymously();

  Future<void> signOut();
}

/// In-memory mock authentication repository for development and unit testing.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({AuthUser? initialUser})
      : _currentUser = initialUser,
        _controller = StreamController<AuthUser?>.broadcast() {
    if (initialUser != null) {
      _controller.add(initialUser);
    }
  }

  AuthUser? _currentUser;
  final StreamController<AuthUser?> _controller;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  Future<AuthUser> signInWithGoogle() async {
    final user = const AuthUser(
      id: 'usr_google_123',
      email: 'alchemist@photalchemy.io',
      displayName: 'Master Alchemist',
      isAnonymous: false,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final user = const AuthUser(
      id: 'usr_anon_guest',
      email: null,
      displayName: 'Guest Alchemist',
      isAnonymous: true,
    );
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
