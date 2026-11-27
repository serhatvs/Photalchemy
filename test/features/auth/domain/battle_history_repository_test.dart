import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/auth/domain/battle_history_repository.dart';

void main() {
  group('BattleHistoryRecord and FirestoreBattleHistoryRepository', () {
    late RuleEnforcingInMemoryFirestoreGateway gateway;
    String? currentUid;
    late FirestoreBattleHistoryRepository repository;

    final aliceVictory = BattleHistoryRecord(
      id: 'battle-1',
      userId: 'user_alice',
      outcome: BattleOutcome.victory,
      turnsPlayed: 6,
      playerFinalHp: 4,
      enemyFinalHp: 0,
    );

    setUp(() {
      gateway = RuleEnforcingInMemoryFirestoreGateway();
      currentUid = 'user_alice';
      repository = FirestoreBattleHistoryRepository(
        gateway: gateway,
        authenticatedUidProvider: () => currentUid,
      );
    });

    test('authenticated owner can record and list battle history', () async {
      await repository.recordBattle(
        userId: 'user_alice',
        record: aliceVictory,
      );

      final battles = await repository.getBattles(userId: 'user_alice');
      expect(battles, hasLength(1));
      expect(battles.first.id, 'battle-1');
      expect(battles.first.outcome, BattleOutcome.victory);
      expect(battles.first.turnsPlayed, 6);
      expect(battles.first.playerFinalHp, 4);
      expect(battles.first.enemyFinalHp, 0);
    });

    test('rejects unauthenticated and cross-user battle reads and writes',
        () async {
      await repository.recordBattle(
        userId: 'user_alice',
        record: aliceVictory,
      );

      currentUid = null;
      expect(
        () => repository.getBattles(userId: 'user_alice'),
        throwsA(isA<BattleHistoryRepositoryException>()),
      );

      currentUid = 'user_bob';
      expect(
        () => repository.getBattles(userId: 'user_alice'),
        throwsA(isA<BattleHistoryRepositoryException>()),
      );
      expect(
        () => repository.recordBattle(
          userId: 'user_alice',
          record: aliceVictory,
        ),
        throwsA(isA<BattleHistoryRepositoryException>()),
      );
    });

    test('firestore.rules denies mutating existing battle history records',
        () async {
      await repository.recordBattle(
        userId: 'user_alice',
        record: aliceVictory,
      );

      final tampered = BattleHistoryRecord(
        id: 'battle-1',
        userId: 'user_alice',
        outcome: BattleOutcome.victory,
        turnsPlayed: 1,
        playerFinalHp: 10,
        enemyFinalHp: 0,
      );

      expect(
        () => repository.recordBattle(
          userId: 'user_alice',
          record: tampered,
        ),
        throwsA(isA<BattleHistoryRepositoryException>()),
      );
    });

    test('firestore.rules rejects out-of-range battle payloads', () async {
      expect(
        () => gateway.setDocument(
          path: 'users/user_alice/battles/battle-hacked',
          data: {
            'id': 'battle-hacked',
            'userId': 'user_alice',
            'outcome': 'victory',
            'turnsPlayed': 999, // Invalid: exceeds max 51 turns
            'playerFinalHp': 10,
            'enemyFinalHp': 0,
          },
          authenticatedUid: 'user_alice',
        ),
        throwsA(isA<FirestoreSecurityException>()),
      );
    });
  });
}
