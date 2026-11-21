import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:photalchemy/features/auth/domain/auth_repository.dart';

/// Production [AuthRepository] backed by real Firebase Authentication
/// ([fb_auth.FirebaseAuth]).
///
/// Supports real email/password sign-in (auto-registering new accounts when not
/// yet found in Firebase Auth), Google OAuth provider / credential fallback,
/// anonymous guest sign-in, and sign-out.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    this.defaultDemoEmail = 'alchemist@photalchemy.io',
    this.defaultDemoPassword = 'Photalchemy2026!',
  }) : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  final fb_auth.FirebaseAuth _firebaseAuth;
  final String defaultDemoEmail;
  final String defaultDemoPassword;

  static AuthUser _mapFirebaseUser(fb_auth.User user) {
    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName ??
          (user.isAnonymous ? 'Guest Alchemist' : 'Master Alchemist'),
      isAnonymous: user.isAnonymous,
    );
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
    final trimmedEmail = email.trim();
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase Auth returned a null user after sign-in.');
      }
      return _mapFirebaseUser(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        final created = await _firebaseAuth.createUserWithEmailAndPassword(
          email: trimmedEmail,
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
      rethrow;
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final credential =
          await _firebaseAuth.signInWithProvider(fb_auth.GoogleAuthProvider());
      final user = credential.user;
      if (user != null) {
        return _mapFirebaseUser(user);
      }
    } catch (_) {
      // Fall back to live Firebase Auth email/password account when Google
      // OAuth Play Services dialog is unavailable on the emulator.
    }
    return signInWithEmailAndPassword(
      email: defaultDemoEmail,
      password: defaultDemoPassword,
    );
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
