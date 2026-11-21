import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:photalchemy/features/auth/domain/auth_repository.dart';

/// Production [AuthRepository] backed by real Firebase Authentication
/// ([fb_auth.FirebaseAuth]).
///
/// Enforces real Firebase Authentication errors without silent fallbacks:
/// - [signInWithEmailAndPassword] authenticates an existing account and throws
///   on wrong email, wrong password, or user-not-found.
/// - [registerWithEmailAndPassword] creates a brand-new account in Firebase
///   Auth and throws if the email is malformed, already in use, or password is
///   too weak.
/// - [signInWithGoogle] invokes the native Firebase Google OAuth provider and
///   surfaces any configuration or cancellation errors directly.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  final fb_auth.FirebaseAuth _firebaseAuth;

  static AuthUser _mapFirebaseUser(fb_auth.User user) {
    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName ??
          (user.isAnonymous ? 'Guest Alchemist' : 'Master Alchemist'),
      isAnonymous: user.isAnonymous,
    );
  }

  static void _validateCredentials(String email, String password) {
    final trimmed = email.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (trimmed.isEmpty || !emailRegex.hasMatch(trimmed)) {
      throw fb_auth.FirebaseAuthException(
        code: 'invalid-email',
        message: 'Please enter a valid email address (e.g. name@domain.com).',
      );
    }
    if (password.isEmpty) {
      throw fb_auth.FirebaseAuthException(
        code: 'missing-password',
        message: 'Please enter your password.',
      );
    }
  }

  @override
  AuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
          (user) => user == null ? null : _mapFirebaseUser(user),
        );
  }

  @override
  Future<AuthUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _validateCredentials(email, password);
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Auth returned a null user after sign-in.');
    }
    return _mapFirebaseUser(user);
  }

  @override
  Future<AuthUser> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _validateCredentials(email, password);
    if (password.length < 6) {
      throw fb_auth.FirebaseAuthException(
        code: 'weak-password',
        message: 'Password must be at least 6 characters long.',
      );
    }
    final created = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = created.user;
    if (user == null) {
      throw StateError(
        'Firebase Auth returned a null user after account registration.',
      );
    }
    await user.updateDisplayName('Master Alchemist');
    return _mapFirebaseUser(_firebaseAuth.currentUser ?? user);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final credential =
        await _firebaseAuth.signInWithProvider(fb_auth.GoogleAuthProvider());
    final user = credential.user;
    if (user == null) {
      throw StateError('Google sign-in did not return an authenticated user.');
    }
    return _mapFirebaseUser(user);
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Auth returned a null anonymous user.');
    }
    return _mapFirebaseUser(user);
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
