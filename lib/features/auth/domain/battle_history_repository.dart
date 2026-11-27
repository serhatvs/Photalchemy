import 'package:photalchemy/core/storage/firestore_gateway.dart';

enum BattleOutcome { victory, defeat, draw }

/// Immutable dungeon encounter summary persisted at
/// `/users/{userId}/battles/{battleId}`.
class BattleHistoryRecord {
  BattleHistoryRecord({
    required this.id,
    required this.userId,
    required this.outcome,
    required this.turnsPlayed,
    required this.playerFinalHp,
    required this.enemyFinalHp,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Battle id must be nonempty');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'userId must be nonempty');
    }
    RangeError.checkValueInInterval(turnsPlayed, 1, 51, 'turnsPlayed');
    RangeError.checkValueInInterval(playerFinalHp, 0, 10, 'playerFinalHp');
    RangeError.checkValueInInterval(enemyFinalHp, 0, 10, 'enemyFinalHp');
  }

  factory BattleHistoryRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final userId = json['userId'];
    final outcomeName = json['outcome'];
    final turnsPlayed = json['turnsPlayed'];
    final playerFinalHp = json['playerFinalHp'];
    final enemyFinalHp = json['enemyFinalHp'];

    if (id is! String ||
        userId is! String ||
        outcomeName is! String ||
        turnsPlayed is! int ||
        playerFinalHp is! int ||
        enemyFinalHp is! int) {
      throw const FormatException(
          'Invalid or missing BattleHistoryRecord JSON');
    }

    final BattleOutcome outcome;
    try {
      outcome = BattleOutcome.values.byName(outcomeName);
    } catch (_) {
      throw FormatException('Unknown BattleOutcome: $outcomeName');
    }

    return BattleHistoryRecord(
      id: id,
      userId: userId,
      outcome: outcome,
      turnsPlayed: turnsPlayed,
      playerFinalHp: playerFinalHp,
      enemyFinalHp: enemyFinalHp,
    );
  }

  final String id;
  final String userId;
  final BattleOutcome outcome;
  final int turnsPlayed;
  final int playerFinalHp;
  final int enemyFinalHp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'outcome': outcome.name,
        'turnsPlayed': turnsPlayed,
        'playerFinalHp': playerFinalHp,
        'enemyFinalHp': enemyFinalHp,
      };
}

/// Exception thrown when battle history repository operations fail.
class BattleHistoryRepositoryException implements Exception {
  const BattleHistoryRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'BattleHistoryRepositoryException: $message';
}

/// Contract for user-scoped battle match history persistence
/// (`/users/{userId}/battles/{battleId}`).
abstract class BattleHistoryRepository {
  Future<List<BattleHistoryRecord>> getBattles({required String userId});

  Future<void> recordBattle({
    required String userId,
    required BattleHistoryRecord record,
  });
}

/// Firestore-backed implementation of [BattleHistoryRepository] enforcing
/// owner-only access and immutable battle record rules.
class FirestoreBattleHistoryRepository implements BattleHistoryRepository {
  FirestoreBattleHistoryRepository({
    required this.gateway,
    required this.authenticatedUidProvider,
  });

  final FirestoreGateway gateway;
  final String? Function() authenticatedUidProvider;

  @override
  Future<List<BattleHistoryRecord>> getBattles({
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID must be nonempty');
    }
    try {
      final docs = await gateway.getCollection(
        collectionPath: 'users/$userId/battles',
        authenticatedUid: authenticatedUidProvider(),
      );
      return docs.map(BattleHistoryRecord.fromJson).toList();
    } on FirestoreSecurityException catch (e) {
      throw BattleHistoryRepositoryException(e.message, cause: e);
    } on FormatException catch (e) {
      throw BattleHistoryRepositoryException(
        'Malformed battle document in Firestore',
        cause: e,
      );
    }
  }

  @override
  Future<void> recordBattle({
    required String userId,
    required BattleHistoryRecord record,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID must be nonempty');
    }
    if (record.userId != userId) {
      throw const BattleHistoryRepositoryException(
        'Battle record userId does not match authenticated userId.',
      );
    }
    try {
      await gateway.setDocument(
        path: 'users/$userId/battles/${record.id}',
        data: record.toJson(),
        authenticatedUid: authenticatedUidProvider(),
      );
    } on FirestoreSecurityException catch (e) {
      throw BattleHistoryRepositoryException(e.message, cause: e);
    }
  }
}
