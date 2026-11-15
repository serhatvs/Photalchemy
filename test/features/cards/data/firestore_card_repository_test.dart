import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/cards/data/firestore_card_repository.dart';
import 'package:photalchemy/features/cards/domain/card_repository.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

void main() {
  group('FirestoreCardRepository and Security Rules', () {
    late RuleEnforcingInMemoryFirestoreGateway gateway;
    String? currentUid;
    late FirestoreCardRepository repository;

    final aliceCard = GameCard(
      id: 'card-flame-1',
      ownerId: 'user_alice',
      type: CardType.attack,
      rarity: CardRarity.rare,
      stats: const CardStats(strength: 7),
      generationVersion: 'color-v0',
    );

    setUp(() {
      gateway = RuleEnforcingInMemoryFirestoreGateway();
      currentUid = 'user_alice';
      repository = FirestoreCardRepository(
        gateway: gateway,
        authenticatedUidProvider: () => currentUid,
      );
    });

    test('authenticated owner can save, list, and delete their cards',
        () async {
      await repository.saveCard(userId: 'user_alice', card: aliceCard);
      final cards = await repository.getCards(userId: 'user_alice');

      expect(cards, hasLength(1));
      expect(cards.first, aliceCard);

      await repository.deleteCard(
        userId: 'user_alice',
        cardId: 'card-flame-1',
      );
      expect(await repository.getCards(userId: 'user_alice'), isEmpty);
    });

    test('rejects unauthenticated card reads and writes', () async {
      currentUid = null;
      expect(
        () => repository.getCards(userId: 'user_alice'),
        throwsA(isA<CardRepositoryException>()),
      );
      expect(
        () => repository.saveCard(userId: 'user_alice', card: aliceCard),
        throwsA(isA<CardRepositoryException>()),
      );
    });

    test('rejects cross-user card reads, writes, and deletes', () async {
      await repository.saveCard(userId: 'user_alice', card: aliceCard);

      // Switch authenticated user to Bob
      currentUid = 'user_bob';

      expect(
        () => repository.getCards(userId: 'user_alice'),
        throwsA(isA<CardRepositoryException>()),
      );
      expect(
        () => repository.saveCard(userId: 'user_alice', card: aliceCard),
        throwsA(isA<CardRepositoryException>()),
      );
      expect(
        () => repository.deleteCard(
          userId: 'user_alice',
          cardId: 'card-flame-1',
        ),
        throwsA(isA<CardRepositoryException>()),
      );
    });

    test('firestore.rules validation blocks tampered out-of-range card writes',
        () async {
      expect(
        () => gateway.setDocument(
          path: 'users/user_alice/cards/hacked-card',
          data: {
            'id': 'hacked-card',
            'ownerId': 'user_alice',
            'type': 'attack',
            'rarity': 'epic',
            'stats': {'strength': 999}, // Invalid: exceeds 1..10 bound
            'generationVersion': 'color-v0',
          },
          authenticatedUid: 'user_alice',
        ),
        throwsA(isA<FirestoreSecurityException>()),
      );
    });

    test(
        'firestore.rules denies mutating existing cards to prevent rarity/strength escalation',
        () async {
      await repository.saveCard(userId: 'user_alice', card: aliceCard);

      final forgedUpgrade = aliceCard.copyWith(
        rarity: CardRarity.epic,
        stats: const CardStats(strength: 10),
      );

      expect(
        () => repository.saveCard(userId: 'user_alice', card: forgedUpgrade),
        throwsA(isA<CardRepositoryException>()),
      );
    });

    test('surfaces offline unavailable state as CardRepositoryException',
        () async {
      gateway.simulateOffline = true;
      expect(
        () => repository.getCards(userId: 'user_alice'),
        throwsA(isA<CardRepositoryException>()),
      );
    });
  });
}
