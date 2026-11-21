import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/app/app_controller.dart';
import 'package:photalchemy/core/notifications/notification_service.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/auth/domain/auth_repository.dart';
import 'package:photalchemy/features/auth/domain/profile_repository.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/data/firestore_card_repository.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';

class _HangingEnemyPolicy implements EnemyPolicy {
  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return observation.legalActions.first.id;
  }
}

void main() {
  group('AppController', () {
    test('captures through ColorFeatureExtractor across all 4 card archetypes',
        () async {
      final controller = AppController();
      addTearDown(controller.dispose);

      expect(controller.collection, hasLength(1));

      await controller.captureAndTransmute();
      await controller.captureAndTransmute();
      await controller.captureAndTransmute();
      await controller.captureAndTransmute();

      expect(controller.collection, hasLength(5));
      final generatedTypes =
          controller.collection.take(4).map((card) => card.type).toSet();
      expect(
        generatedTypes,
        containsAll([
          CardType.attack,
          CardType.defense,
          CardType.stun,
          CardType.reflect,
        ]),
      );
    });

    test(
        'persists cards and cell capture counts on sign-in and clears on sign-out',
        () async {
      final auth = MockAuthRepository();
      final gateway = RuleEnforcingInMemoryFirestoreGateway();
      final cardsRepo = FirestoreCardRepository(
        gateway: gateway,
        authenticatedUidProvider: () => auth.currentUser?.id,
      );
      final profileRepo = FirestoreProfileRepository(
        gateway: gateway,
        authenticatedUidProvider: () => auth.currentUser?.id,
      );

      final controller = AppController(
        authRepository: auth,
        cardRepository: cardsRepo,
        profileRepository: profileRepo,
      );
      addTearDown(controller.dispose);

      await controller.signInWithGoogle();
      expect(controller.isAuthenticated, isTrue);

      await controller.captureAndTransmute();
      final saved = await cardsRepo.getCards(userId: controller.userId!);
      expect(saved, hasLength(1));
      expect(saved.first.id, 'card-2');

      final profile = await profileRepo.getProfile(userId: controller.userId!);
      expect(profile?.cellCaptureCounts.values.first, 1);

      await controller.signOut();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.collection, hasLength(1));
      expect(controller.collection.first.id, 'starter-ember');

      await controller.signInWithGoogle();
      expect(controller.collection.any((c) => c.id == 'card-2'), isTrue);
    });

    test('surfaces offline Firestore error cleanly without crashing', () async {
      final auth = MockAuthRepository();
      final gateway = RuleEnforcingInMemoryFirestoreGateway();
      final cardsRepo = FirestoreCardRepository(
        gateway: gateway,
        authenticatedUidProvider: () => auth.currentUser?.id,
      );
      final profileRepo = FirestoreProfileRepository(
        gateway: gateway,
        authenticatedUidProvider: () => auth.currentUser?.id,
      );

      final controller = AppController(
        authRepository: auth,
        cardRepository: cardsRepo,
        profileRepository: profileRepo,
      );
      addTearDown(controller.dispose);

      await controller.signInWithGoogle();
      gateway.simulateOffline = true;
      await controller.reloadCollection();

      expect(controller.collectionErrorMessage, isNotNull);
      expect(controller.isCollectionLoading, isFalse);
    });

    test('falls back safely when enemy policy times out during battle turn',
        () async {
      final safePolicy = SafeFallbackEnemyPolicy(
        primaryPolicy: _HangingEnemyPolicy(),
        timeout: const Duration(milliseconds: 20),
      );
      final controller = AppController(enemyPolicy: safePolicy);
      addTearDown(controller.dispose);

      await controller.playBattleTurn(controller.playerActions.first);

      expect(safePolicy.fallbackActivations, 1);
      expect(controller.battleState.turnNumber, 2);
      expect(controller.lastTurnSummary, isNotNull);

      controller.resetBattle();
      expect(controller.battleState.turnNumber, 1);
      expect(controller.lastTurnSummary, isNull);
    });

    test('blocks capture when camera permission denied and handles FCM denial',
        () async {
      final notifications = MockFcmNotificationService(simulateDenial: true);
      final controller = AppController(notificationService: notifications);
      addTearDown(controller.dispose);

      controller.setCameraPermission(false);
      await controller.captureAndTransmute();
      expect(controller.collection, hasLength(1));

      controller.grantCameraPermission();
      controller.setLocationPermission(LocationPermission.optedOut);
      await controller.captureAndTransmute();
      expect(controller.collection, hasLength(2));

      await controller.signInWithGoogle();
      await controller.toggleNotifications(true);
      expect(controller.notificationsEnabled, isFalse);
    });

    test('signs in with Firebase email and password and creates profile',
        () async {
      final auth = MockAuthRepository();
      final gateway = RuleEnforcingInMemoryFirestoreGateway();
      final profileRepo = FirestoreProfileRepository(
        gateway: gateway,
        authenticatedUidProvider: () => auth.currentUser?.id,
      );
      final controller = AppController(
        authRepository: auth,
        profileRepository: profileRepo,
      );
      addTearDown(controller.dispose);

      await controller.signInWithEmailAndPassword(
        email: 'alchemist@photalchemy.io',
        password: 'Photalchemy2026!',
      );
      expect(controller.isAuthenticated, isTrue);
      expect(controller.userEmail, 'alchemist@photalchemy.io');

      final profile = await profileRepo.getProfile(userId: controller.userId!);
      expect(profile?.email, 'alchemist@photalchemy.io');
    });
  });
}
