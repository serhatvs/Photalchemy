import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/auth/domain/auth_repository.dart';

void main() {
  group('MockAuthRepository', () {
    test('starts with null user and signs in with Google', () async {
      final repo = MockAuthRepository();
      expect(repo.currentUser, isNull);

      final emissions = <AuthUser?>[];
      final sub = repo.authStateChanges().listen(emissions.add);

      final user = await repo.signInWithGoogle();
      expect(user.email, 'alchemist@photalchemy.io');
      expect(user.isAnonymous, isFalse);
      expect(repo.currentUser, equals(user));

      await repo.signOut();
      expect(repo.currentUser, isNull);

      await pumpEventQueue();
      expect(emissions, [user, null]);

      await sub.cancel();
      repo.dispose();
    });

    test('signs in anonymously as guest', () async {
      final repo = MockAuthRepository();

      final guest = await repo.signInAnonymously();
      expect(guest.isAnonymous, isTrue);
      expect(guest.displayName, 'Guest Alchemist');
      expect(repo.currentUser, equals(guest));

      repo.dispose();
    });

    test('AuthUser value equality and hashCode', () {
      const u1 = AuthUser(
        id: '1',
        email: 'test@io.com',
        displayName: 'A',
        isAnonymous: false,
      );
      const u2 = AuthUser(
        id: '1',
        email: 'test@io.com',
        displayName: 'A',
        isAnonymous: false,
      );
      const u3 = AuthUser(
        id: '2',
        email: 'test@io.com',
        displayName: 'A',
        isAnonymous: false,
      );

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
    });
  });
}
