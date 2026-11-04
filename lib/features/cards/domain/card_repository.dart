import 'game_card.dart';

/// Exception thrown when card repository operations fail or are rejected.
class CardRepositoryException implements Exception {
  const CardRepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'CardRepositoryException: $message';
}

/// Abstract contract for user-scoped card storage.
///
/// Implemented by FirestoreCardRepository (backend) and InMemoryCardRepository (mock/test).
abstract class CardRepository {
  Future<List<GameCard>> getCards({required String userId});

  Future<void> saveCard({required String userId, required GameCard card});

  Future<void> deleteCard({required String userId, required String cardId});
}

/// Thread-safe in-memory card repository with strict cross-user isolation.
///
/// Supports simulated failure modes for testing offline and error paths.
class InMemoryCardRepository implements CardRepository {
  InMemoryCardRepository({
    Map<String, List<GameCard>>? initialCards,
    this.simulateFailure = false,
  }) : _storage = {} {
    if (initialCards != null) {
      for (final entry in initialCards.entries) {
        _storage[entry.key] = List<GameCard>.from(entry.value);
      }
    }
  }

  final Map<String, List<GameCard>> _storage;
  bool simulateFailure;

  void _checkFailure() {
    if (simulateFailure) {
      throw const CardRepositoryException(
          'Simulated network / storage failure');
    }
  }

  @override
  Future<List<GameCard>> getCards({required String userId}) async {
    _checkFailure();
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID must be nonempty');
    }
    final userCards = _storage[userId];
    if (userCards == null) return const [];
    return List<GameCard>.unmodifiable(userCards);
  }

  @override
  Future<void> saveCard(
      {required String userId, required GameCard card}) async {
    _checkFailure();
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID must be nonempty');
    }
    if (card.ownerId != userId) {
      throw const CardRepositoryException(
        'Card ownerId does not match authenticated userId. Cross-user writes are rejected.',
      );
    }

    final userCards = _storage.putIfAbsent(userId, () => <GameCard>[]);
    final existingIndex = userCards.indexWhere((c) => c.id == card.id);

    if (existingIndex >= 0) {
      userCards[existingIndex] = card;
    } else {
      userCards.add(card);
    }
  }

  @override
  Future<void> deleteCard({
    required String userId,
    required String cardId,
  }) async {
    _checkFailure();
    if (userId.trim().isEmpty || cardId.trim().isEmpty) {
      throw ArgumentError('userId and cardId must be nonempty');
    }

    final userCards = _storage[userId];
    if (userCards != null) {
      userCards.removeWhere((c) => c.id == cardId);
    }
  }
}
