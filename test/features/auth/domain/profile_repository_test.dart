import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/auth/domain/profile_repository.dart';

void main() {
  group('UserProfile serialization and validation', () {
    test('round-trips JSON with coarse cell counts and notification consent',
        () {
      final profile = UserProfile(
        id: 'user_123',
        email: 'alchemist@photalchemy.io',
        displayName: 'Alchemist',
        isAnonymous: false,
        notificationsEnabled: true,
        cellCaptureCounts: {'38.72:35.48': 2},
      );

      final json = profile.toJson();
      final decoded = UserProfile.fromJson(json);

      expect(decoded.id, 'user_123');
      expect(decoded.email, 'alchemist@photalchemy.io');
      expect(decoded.notificationsEnabled, isTrue);
      expect(decoded.cellCaptureCounts['38.72:35.48'], 2);
    });

    test('rejects empty id or negative cell counts', () {
      expect(
        () => UserProfile(id: '  ', isAnonymous: false),
        throwsArgumentError,
      );
      expect(
        () => UserProfile(
          id: 'user_1',
          isAnonymous: false,
          cellCaptureCounts: {'38.72:35.48': -1},
        ),
        throwsArgumentError,
      );
    });
  });

  group('FirestoreProfileRepository and Security Rules', () {
    late RuleEnforcingInMemoryFirestoreGateway gateway;
    String? currentUid;
    late FirestoreProfileRepository repository;

    setUp(() {
      gateway = RuleEnforcingInMemoryFirestoreGateway();
      currentUid = 'user_alice';
      repository = FirestoreProfileRepository(
        gateway: gateway,
        authenticatedUidProvider: () => currentUid,
      );
    });

    test('authenticated owner can create, read, increment cells and delete',
        () async {
      final profile = UserProfile(
        id: 'user_alice',
        email: 'alice@photalchemy.io',
        isAnonymous: false,
      );

      await repository.saveProfile(userId: 'user_alice', profile: profile);
      final loaded = await repository.getProfile(userId: 'user_alice');
      expect(loaded?.email, 'alice@photalchemy.io');

      final updated = await repository.incrementCellCapture(
        userId: 'user_alice',
        cellKey: '38.72:35.48',
      );
      expect(updated.cellCaptureCounts['38.72:35.48'], 1);

      await repository.deleteProfile(userId: 'user_alice');
      expect(await repository.getProfile(userId: 'user_alice'), isNull);
    });

    test('rejects unauthenticated profile reads and writes', () async {
      currentUid = null;
      expect(
        () => repository.getProfile(userId: 'user_alice'),
        throwsA(isA<ProfileRepositoryException>()),
      );
      expect(
        () => repository.saveProfile(
          userId: 'user_alice',
          profile: UserProfile(id: 'user_alice', isAnonymous: false),
        ),
        throwsA(isA<ProfileRepositoryException>()),
      );
    });

    test('rejects cross-user profile reads, writes, and deletes', () async {
      // Alice saves her profile
      await repository.saveProfile(
        userId: 'user_alice',
        profile: UserProfile(id: 'user_alice', isAnonymous: false),
      );

      // Bob signs in and attempts to read/modify/delete Alice's profile
      currentUid = 'user_bob';
      expect(
        () => repository.getProfile(userId: 'user_alice'),
        throwsA(isA<ProfileRepositoryException>()),
      );
      expect(
        () => repository.saveProfile(
          userId: 'user_alice',
          profile: UserProfile(id: 'user_alice', isAnonymous: false),
        ),
        throwsA(isA<ProfileRepositoryException>()),
      );
      expect(
        () => repository.deleteProfile(userId: 'user_alice'),
        throwsA(isA<ProfileRepositoryException>()),
      );
    });

    test('default-deny rule blocks arbitrary root collections', () async {
      expect(
        () => gateway.getDocument(
          path: 'admin_secrets/config',
          authenticatedUid: 'user_alice',
        ),
        throwsA(isA<FirestoreSecurityException>()),
      );
      expect(
        () => gateway.setDocument(
          path: 'global_leaderboard/entry_1',
          data: {'score': 999},
          authenticatedUid: 'user_alice',
        ),
        throwsA(isA<FirestoreSecurityException>()),
      );
    });

    test('surfaces offline failure cleanly', () async {
      gateway.simulateOffline = true;
      expect(
        () => repository.getProfile(userId: 'user_alice'),
        throwsA(isA<ProfileRepositoryException>()),
      );
    });
  });
}
