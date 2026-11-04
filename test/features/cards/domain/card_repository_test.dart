import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/cards/domain/card_repository.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

void main() {
  GameCard makeCard(String id, String ownerId) {
    return GameCard(
      id: id,
      ownerId: ownerId,
      type: CardType.attack,
      rarity: CardRarity.common,
      stats: const CardStats(strength: 5),
      generationVersion: 'color-v0',
    );
  }

  group('InMemoryCardRepository', () {
    test('saves, retrieves and isolates cards per user', () async {
      final repo = InMemoryCardRepository();

      final cardA = makeCard('card-1', 'user-A');
      final cardB = makeCard('card-2', 'user-B');

      await repo.saveCard(userId: 'user-A', card: cardA);
      await repo.saveCard(userId: 'user-B', card: cardB);

      final cardsUserA = await repo.getCards(userId: 'user-A');
      final cardsUserB = await repo.getCards(userId: 'user-B');

      // Strict user isolation
      expect(cardsUserA, [cardA]);
      expect(cardsUserB, [cardB]);
    });

    test('rejects cross-user writes when card ownerId does not match userId',
        () async {
      final repo = InMemoryCardRepository();
      final card = makeCard('card-hack', 'user-B');

      expect(
        () => repo.saveCard(userId: 'user-A', card: card),
        throwsA(isA<CardRepositoryException>()),
      );
    });

    test('updates existing card and deletes card cleanly', () async {
      final repo = InMemoryCardRepository();
      final initial = makeCard('c1', 'user-A');
      final updated = initial.copyWith(stats: const CardStats(strength: 9));

      await repo.saveCard(userId: 'user-A', card: initial);
      expect((await repo.getCards(userId: 'user-A')).first.stats.strength, 5);

      await repo.saveCard(userId: 'user-A', card: updated);
      expect((await repo.getCards(userId: 'user-A')).first.stats.strength, 9);

      await repo.deleteCard(userId: 'user-A', cardId: 'c1');
      expect(await repo.getCards(userId: 'user-A'), isEmpty);
    });

    test('simulated failure throws CardRepositoryException', () async {
      final repo = InMemoryCardRepository(simulateFailure: true);

      expect(
        () => repo.getCards(userId: 'user-A'),
        throwsA(isA<CardRepositoryException>()),
      );
      expect(
        () => repo.saveCard(userId: 'user-A', card: makeCard('c', 'user-A')),
        throwsA(isA<CardRepositoryException>()),
      );
    });

    test('validates nonempty user IDs', () async {
      final repo = InMemoryCardRepository();

      expect(() => repo.getCards(userId: '   '), throwsArgumentError);
      expect(
        () => repo.saveCard(userId: '', card: makeCard('c', 'user')),
        throwsArgumentError,
      );
    });
  });
}
