import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/cards/domain/card_repository.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

/// Firestore-backed implementation of [CardRepository] storing user cards at
/// `/users/{userId}/cards/{cardId}` and enforcing per-user isolation.
class FirestoreCardRepository implements CardRepository {
  FirestoreCardRepository({
    required this.gateway,
    required this.authenticatedUidProvider,
  });

  final FirestoreGateway gateway;
  final String? Function() authenticatedUidProvider;

  @override
  Future<List<GameCard>> getCards({required String userId}) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID must be nonempty');
    }
    try {
      final docs = await gateway.getCollection(
        collectionPath: 'users/$userId/cards',
        authenticatedUid: authenticatedUidProvider(),
      );
      return docs.map(GameCard.fromJson).toList();
    } on FirestoreSecurityException catch (e) {
      throw CardRepositoryException(e.message, cause: e);
    } on FormatException catch (e) {
      throw CardRepositoryException('Malformed card document in Firestore',
          cause: e);
    }
  }

  @override
  Future<void> saveCard({
    required String userId,
    required GameCard card,
  }) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID must be nonempty');
    }
    if (card.ownerId != userId) {
      throw const CardRepositoryException(
        'Card ownerId does not match authenticated userId. Cross-user writes are rejected.',
      );
    }
    try {
      await gateway.setDocument(
        path: 'users/$userId/cards/${card.id}',
        data: card.toJson(),
        authenticatedUid: authenticatedUidProvider(),
      );
    } on FirestoreSecurityException catch (e) {
      throw CardRepositoryException(e.message, cause: e);
    }
  }

  @override
  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    if (userId.trim().isEmpty || cardId.trim().isEmpty) {
      throw ArgumentError('userId and cardId must be nonempty');
    }
    try {
      await gateway.deleteDocument(
        path: 'users/$userId/cards/$cardId',
        authenticatedUid: authenticatedUidProvider(),
      );
    } on FirestoreSecurityException catch (e) {
      throw CardRepositoryException(e.message, cause: e);
    }
  }
}
