import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:photalchemy/core/notifications/notification_service.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/auth/domain/auth_repository.dart';
import 'package:photalchemy/features/auth/domain/battle_history_repository.dart';
import 'package:photalchemy/features/auth/domain/profile_repository.dart';
import 'package:photalchemy/features/battle/domain/battle_engine.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/data/firestore_card_repository.dart';
import 'package:photalchemy/features/cards/domain/card_generator.dart';
import 'package:photalchemy/features/cards/domain/card_repository.dart';
import 'package:photalchemy/features/cards/domain/color_feature_extractor.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/exploration/domain/location_service.dart';
import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';

/// Application-wide state controller decoupling Photalchemy UI screens from
/// domain engines, repository persistence, and notification services.
class AppController extends ChangeNotifier {
  AppController({
    AuthRepository? authRepository,
    CardRepository? cardRepository,
    ProfileRepository? profileRepository,
    BattleHistoryRepository? battleHistoryRepository,
    NotificationService? notificationService,
    LocationService? locationService,
    CardGenerator cardGenerator = const CardGenerator(),
    ColorFeatureExtractor colorExtractor = const ColorFeatureExtractor(),
    RarityPolicy rarityPolicy = const RarityPolicy(),
    BattleEngine battleEngine = const BattleEngine(),
    EnemyPolicy? enemyPolicy,
    CoarseLocation? demoLocation,
  })  : _cardGenerator = cardGenerator,
        _colorExtractor = colorExtractor,
        _rarityPolicy = rarityPolicy,
        _battleEngine = battleEngine,
        _locationService = locationService ??
            SimulatedLocationService(
              initialLocation: demoLocation,
            ) {
    final gateway = RuleEnforcingInMemoryFirestoreGateway();
    _authRepository = authRepository ?? MockAuthRepository();
    _cardRepository = cardRepository ??
        FirestoreCardRepository(
          gateway: gateway,
          authenticatedUidProvider: () => _authRepository.currentUser?.id,
        );
    _profileRepository = profileRepository ??
        FirestoreProfileRepository(
          gateway: gateway,
          authenticatedUidProvider: () => _authRepository.currentUser?.id,
        );
    _battleHistoryRepository = battleHistoryRepository ??
        FirestoreBattleHistoryRepository(
          gateway: gateway,
          authenticatedUidProvider: () => _authRepository.currentUser?.id,
        );
    _notificationService = notificationService ?? MockFcmNotificationService();
    _enemyPolicy = enemyPolicy ??
        SafeFallbackEnemyPolicy(
          primaryPolicy: const HeuristicEnemyPolicy(),
        );

    _notificationSub = _notificationService.onNotification.listen((msg) {
      _emitMessage('FCM [${msg.topic}]: ${msg.title} — ${msg.body}');
    });
  }

  static final GameCard starterCard = GameCard(
    id: 'starter-ember',
    ownerId: 'player',
    type: CardType.attack,
    rarity: CardRarity.common,
    stats: const CardStats(strength: 4),
    generationVersion: 'color-v0',
  );

  static BattleState _initialBattleState() => BattleState(
        turnNumber: 1,
        player: const BattleCombatant(
          hp: 10,
          maxHp: 10,
          shield: 0,
          isStunned: false,
        ),
        enemy: const BattleCombatant(
          hp: 10,
          maxHp: 10,
          shield: 0,
          isStunned: false,
        ),
      );

  late final AuthRepository _authRepository;
  late final CardRepository _cardRepository;
  late final ProfileRepository _profileRepository;
  late final BattleHistoryRepository _battleHistoryRepository;
  late final NotificationService _notificationService;
  late final EnemyPolicy _enemyPolicy;
  final CardGenerator _cardGenerator;
  final ColorFeatureExtractor _colorExtractor;
  final RarityPolicy _rarityPolicy;
  final BattleEngine _battleEngine;
  final LocationService _locationService;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  StreamSubscription<GameNotification>? _notificationSub;

  int _selectedIndex = 0;
  bool _hasCameraPermission = true;
  Map<String, int> _localCellCaptureCounts = {};
  bool _isAuthenticated = false;
  bool _isAuthBusy = false;
  String? _userId;
  String? _userEmail;
  bool _notificationsEnabled = false;

  bool _isCollectionLoading = false;
  String? _collectionErrorMessage;
  final List<GameCard> _collection = [starterCard];
  final List<BattleHistoryRecord> _battleHistory = [];
  int _captureSceneIndex = 0;
  int _mintCounter = 1;
  int _battleCounter = 0;

  String? _authErrorMessage;

  BattleState _battleState = _initialBattleState();
  bool _isResolvingTurn = false;
  String? _lastTurnSummary;

  final List<LegalEnemyAction> _playerActions = [
    LegalEnemyAction(
      id: 'slash',
      cardType: CardType.attack,
      strength: 4,
      effectDescription: 'Deal 4 damage',
    ),
    LegalEnemyAction(
      id: 'guard',
      cardType: CardType.defense,
      strength: 3,
      effectDescription: 'Gain 3 shield',
    ),
    LegalEnemyAction(
      id: 'stun-blast',
      cardType: CardType.stun,
      strength: 2,
      effectDescription: 'Stun opponent for 1 turn',
    ),
    LegalEnemyAction(
      id: 'mirror-ward',
      cardType: CardType.reflect,
      strength: 3,
      effectDescription: 'Reflect incoming attack',
    ),
  ];

  final List<LegalEnemyAction> _enemyActions = [
    LegalEnemyAction(
      id: 'enemy-strike',
      cardType: CardType.attack,
      strength: 3,
      effectDescription: 'Deal 3 damage',
    ),
    LegalEnemyAction(
      id: 'enemy-barrier',
      cardType: CardType.defense,
      strength: 3,
      effectDescription: 'Gain 3 shield',
    ),
    LegalEnemyAction(
      id: 'enemy-hex',
      cardType: CardType.stun,
      strength: 2,
      effectDescription: 'Stun opponent for 1 turn',
    ),
    LegalEnemyAction(
      id: 'enemy-mirror',
      cardType: CardType.reflect,
      strength: 3,
      effectDescription: 'Reflect incoming attack',
    ),
  ];

  Stream<String> get messages => _messageController.stream;
  int get selectedIndex => _selectedIndex;
  bool get hasCameraPermission => _hasCameraPermission;
  LocationPermission get locationPermission => _locationService.permission;
  CoarseLocation? get currentLocation => _locationService.currentLocation;
  String get currentCellName => _locationService.currentCellName;
  List<ExplorationCellPreset> get availableCells =>
      _locationService.availableCells;
  int get repeatDecayThreshold => _rarityPolicy.repeatDecayThreshold;
  int get currentCellCaptures {
    final loc = _locationService.currentLocation;
    if (loc == null) return 0;
    return _localCellCaptureCounts[loc.cellKey] ?? 0;
  }

  bool get isCurrentCellDepleted =>
      _locationService.permission == LocationPermission.granted &&
      currentCellCaptures >= _rarityPolicy.repeatDecayThreshold;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthBusy => _isAuthBusy;
  String? get authErrorMessage => _authErrorMessage;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isCollectionLoading => _isCollectionLoading;
  String? get collectionErrorMessage => _collectionErrorMessage;
  List<GameCard> get collection => List.unmodifiable(_collection);
  List<BattleHistoryRecord> get battleHistory =>
      List.unmodifiable(_battleHistory);
  int get victoriesCount =>
      _battleHistory.where((b) => b.outcome == BattleOutcome.victory).length;
  int get defeatsCount =>
      _battleHistory.where((b) => b.outcome == BattleOutcome.defeat).length;
  BattleState get battleState => _battleState;
  bool get isResolvingTurn => _isResolvingTurn;
  String? get lastTurnSummary => _lastTurnSummary;
  List<LegalEnemyAction> get playerActions => List.unmodifiable(_playerActions);

  void selectTab(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }

  void grantCameraPermission() {
    _hasCameraPermission = true;
    notifyListeners();
  }

  void setCameraPermission(bool granted) {
    _hasCameraPermission = granted;
    notifyListeners();
  }

  void setLocationPermission(LocationPermission permission) {
    final service = _locationService;
    if (service is SimulatedLocationService) {
      service.setPermission(permission);
    } else {
      service.setOptOut(permission != LocationPermission.granted);
    }
    notifyListeners();
  }

  Future<void> toggleLocationOptOut(bool optedOut) async {
    await _locationService.setOptOut(optedOut);
    notifyListeners();
  }

  void selectExplorationCell(ExplorationCellPreset preset) {
    _locationService.selectCell(preset);
    notifyListeners();
  }

  /// Generates deterministic sample RGB pixel frames representing diverse
  /// lighting/color scenes so the real [ColorFeatureExtractor] runs in P1 demo mode.
  Uint8List _nextSampleRgbFrame() {
    final scene = _captureSceneIndex % 4;
    _captureSceneIndex += 1;
    switch (scene) {
      case 0:
        // Bright sunlit scene -> attack
        return Uint8List.fromList([245, 220, 140, 250, 210, 130]);
      case 1:
        // Calm neutral indoor scene -> defense
        return Uint8List.fromList([110, 120, 130, 115, 125, 135]);
      case 2:
        // Vivid saturated neon scene -> stun
        return Uint8List.fromList([10, 200, 30, 15, 195, 25]);
      default:
        // High-contrast shadow/highlight scene -> reflect
        return Uint8List.fromList([0, 0, 0, 255, 255, 255]);
    }
  }

  Future<void> captureAndTransmute() async {
    if (!_hasCameraPermission) {
      _emitMessage('Camera permission is required before capturing.');
      return;
    }

    final frameBytes = _nextSampleRgbFrame();
    final features = _colorExtractor.extractFromBytes(frameBytes);
    final existingIds = _collection.map((c) => c.id).toSet();
    do {
      _mintCounter += 1;
    } while (existingIds.contains('card-$_mintCounter'));
    final cardId = 'card-$_mintCounter';
    final ownerId = _isAuthenticated ? (_userId ?? 'player') : 'guest';

    final snapshot = await _locationService.getCurrentSnapshot();
    Map<String, int> cellCounts =
        Map<String, int>.from(_localCellCaptureCounts);
    if (_isAuthenticated && _userId != null) {
      try {
        final profile = await _profileRepository.getProfile(userId: _userId!);
        if (profile != null) {
          cellCounts = Map<String, int>.from(profile.cellCaptureCounts);
          _localCellCaptureCounts = Map<String, int>.from(cellCounts);
        }
      } on ProfileRepositoryException catch (e) {
        _emitMessage('Profile sync warning: ${e.message}');
      }
    }

    final rarity = _rarityPolicy.determineRarity(
      features: features,
      permission: snapshot.permission,
      location: snapshot.location,
      cellCaptureCounts: cellCounts,
    );

    final card = _cardGenerator.generate(
      id: cardId,
      ownerId: ownerId,
      features: features,
      rarity: rarity,
    );

    if (snapshot.isLocationActive && snapshot.location != null) {
      final cellKey = snapshot.location!.cellKey;
      _localCellCaptureCounts[cellKey] = (cellCounts[cellKey] ?? 0) + 1;
    }

    if (_isAuthenticated && _userId != null) {
      try {
        await _cardRepository.saveCard(userId: _userId!, card: card);
        if (snapshot.isLocationActive && snapshot.location != null) {
          final updatedProfile = await _profileRepository.incrementCellCapture(
            userId: _userId!,
            cellKey: snapshot.location!.cellKey,
          );
          _localCellCaptureCounts =
              Map<String, int>.from(updatedProfile.cellCaptureCounts);
        }
      } on CardRepositoryException catch (e) {
        _emitMessage('Failed to save card: ${e.message}');
        return;
      } on ProfileRepositoryException catch (e) {
        _emitMessage('Card saved, but location sync failed: ${e.message}');
      }
    }

    _collection.insert(0, card);
    _collectionErrorMessage = null;
    notifyListeners();
    _emitMessage(
      'Synthesized ${card.type.name.toUpperCase()} card ($cardId)!',
    );

    if (_notificationsEnabled) {
      if (card.rarity == CardRarity.epic) {
        await _triggerOptInNotification(
          title: 'Epic Card Transmuted!',
          body:
              'You synthesized an EPIC ${card.type.name.toUpperCase()} card ($cardId)!',
        );
      } else if (isCurrentCellDepleted) {
        await _triggerOptInNotification(
          title: 'Sector Resonance Depleted',
          body:
              '${_locationService.currentCellName} reached $repeatDecayThreshold/$repeatDecayThreshold captures. Travel to a new cell for rare cards!',
        );
      }
    }
  }

  Future<void> reloadCollection() async {
    if (!_isAuthenticated || _userId == null) {
      _collectionErrorMessage = null;
      notifyListeners();
      return;
    }

    _isCollectionLoading = true;
    _collectionErrorMessage = null;
    notifyListeners();

    try {
      final persisted = await _cardRepository.getCards(userId: _userId!);
      _collection
        ..clear()
        ..addAll(persisted.reversed)
        ..add(starterCard);
      for (final card in persisted) {
        final match = RegExp(r'^card-(\d+)$').firstMatch(card.id);
        if (match != null) {
          final parsed = int.tryParse(match.group(1)!);
          if (parsed != null && parsed > _mintCounter) {
            _mintCounter = parsed;
          }
        }
      }
    } on CardRepositoryException catch (e) {
      _collectionErrorMessage = e.message;
    } finally {
      _isCollectionLoading = false;
      notifyListeners();
    }
  }

  Future<void> playBattleTurn(LegalEnemyAction playerAction) async {
    if (_battleState.isGameOver) {
      _emitMessage('Battle is over! Resetting arena...');
      resetBattle();
      return;
    }

    _isResolvingTurn = true;
    notifyListeners();

    try {
      final enemyObs =
          _battleState.createObservation(legalActions: _enemyActions);
      final proposedEnemyActionId = await _enemyPolicy.chooseAction(enemyObs);
      final enemyAction = validateEnemyAction(enemyObs, proposedEnemyActionId);

      final nextState = _battleEngine.resolveTurn(
        state: _battleState,
        playerAction: playerAction,
        enemyAction: enemyAction,
      );

      _battleState = nextState;
      _lastTurnSummary =
          nextState.history.isNotEmpty ? nextState.history.last.summary : null;
      notifyListeners();

      if (nextState.isGameOver) {
        final winnerText = nextState.winner == CombatantSide.player
            ? 'Victory! Player defeated the enemy!'
            : nextState.winner == CombatantSide.enemy
                ? 'Defeat! Player was defeated!'
                : 'Draw match!';
        _emitMessage(winnerText);
        await _recordCompletedBattle(nextState);
      }
    } finally {
      _isResolvingTurn = false;
      notifyListeners();
    }
  }

  void resetBattle() {
    _battleState = _initialBattleState();
    _lastTurnSummary = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    await _performSignIn(() => _authRepository.signInWithGoogle());
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _performSignIn(
      () => _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _performSignIn(
      () => _authRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> _performSignIn(Future<AuthUser> Function() signInAction) async {
    _isAuthBusy = true;
    _authErrorMessage = null;
    notifyListeners();
    try {
      final user = await signInAction();
      UserProfile? existingProfile;
      try {
        existingProfile = await _profileRepository.getProfile(userId: user.id);
        if (existingProfile == null) {
          await _profileRepository.saveProfile(
            userId: user.id,
            profile: UserProfile(
              id: user.id,
              email: user.email,
              displayName: user.displayName,
              isAnonymous: user.isAnonymous,
              notificationsEnabled: false,
            ),
          );
        }
      } on ProfileRepositoryException catch (e) {
        _emitMessage('Profile load warning: ${e.message}');
      }

      _isAuthenticated = true;
      _userId = user.id;
      _userEmail = user.email;
      _notificationsEnabled = existingProfile?.notificationsEnabled ?? false;
      _localCellCaptureCounts = Map<String, int>.from(
        existingProfile?.cellCaptureCounts ?? const {},
      );

      if (_notificationsEnabled) {
        try {
          final status = await _notificationService.requestPermission();
          if (status == NotificationPermissionStatus.granted) {
            await _notificationService.subscribeToTopic('dungeon_alerts');
          } else {
            _notificationsEnabled = false;
          }
        } catch (_) {
          _notificationsEnabled = false;
        }
      }

      await reloadCollection();
      await reloadBattleHistory();
    } catch (e) {
      final cleaned = e.toString().replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
      _authErrorMessage = cleaned;
      _emitMessage('Authentication failed: $cleaned');
    } finally {
      _isAuthBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _isAuthenticated = false;
    _authErrorMessage = null;
    _userId = null;
    _userEmail = null;
    _notificationsEnabled = false;
    _localCellCaptureCounts = {};
    _collectionErrorMessage = null;
    _collection
      ..clear()
      ..add(starterCard);
    _battleHistory.clear();
    notifyListeners();
  }

  Future<void> reloadBattleHistory() async {
    if (!_isAuthenticated || _userId == null) {
      _battleHistory.clear();
      notifyListeners();
      return;
    }
    try {
      final persisted =
          await _battleHistoryRepository.getBattles(userId: _userId!);
      _battleHistory
        ..clear()
        ..addAll(persisted);
      for (final record in persisted) {
        final match = RegExp(r'^battle-(\d+)$').firstMatch(record.id);
        if (match != null) {
          final parsed = int.tryParse(match.group(1)!);
          if (parsed != null && parsed > _battleCounter) {
            _battleCounter = parsed;
          }
        }
      }
      notifyListeners();
    } on BattleHistoryRepositoryException catch (e) {
      _emitMessage('Battle history sync warning: ${e.message}');
    }
  }

  Future<void> _recordCompletedBattle(BattleState completedState) async {
    final outcome = completedState.winner == CombatantSide.player
        ? BattleOutcome.victory
        : completedState.winner == CombatantSide.enemy
            ? BattleOutcome.defeat
            : BattleOutcome.draw;
    final existingIds = _battleHistory.map((b) => b.id).toSet();
    do {
      _battleCounter += 1;
    } while (existingIds.contains('battle-$_battleCounter'));
    final battleId = 'battle-$_battleCounter';
    final record = BattleHistoryRecord(
      id: battleId,
      userId: _isAuthenticated ? (_userId ?? 'player') : 'guest',
      outcome: outcome,
      turnsPlayed: (completedState.turnNumber - 1).clamp(1, 51),
      playerFinalHp: completedState.player.hp,
      enemyFinalHp: completedState.enemy.hp,
    );

    if (_isAuthenticated && _userId != null) {
      try {
        await _battleHistoryRepository.recordBattle(
          userId: _userId!,
          record: record,
        );
      } on BattleHistoryRepositoryException catch (e) {
        _emitMessage('Failed to save battle history: ${e.message}');
      }
    }

    _battleHistory.insert(0, record);
    notifyListeners();

    if (_notificationsEnabled && outcome == BattleOutcome.victory) {
      await _triggerOptInNotification(
        title: 'Dungeon Victory Recorded!',
        body:
            'Encounter $battleId cleared with ${completedState.player.hp} HP remaining ($victoriesCount total wins).',
      );
    }
  }

  Future<void> _triggerOptInNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _notificationService.sendDemoNotification(
        title: title,
        body: body,
      );
    } catch (_) {
      // Non-fatal if permission is not granted.
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (!_isAuthenticated || _userId == null) return;

    if (enabled) {
      final status = await _notificationService.requestPermission();
      if (status != NotificationPermissionStatus.granted) {
        _emitMessage('Notification permission denied.');
        return;
      }
      await _notificationService.subscribeToTopic('dungeon_alerts');
    } else {
      await _notificationService.unsubscribeFromTopic('dungeon_alerts');
    }

    try {
      final profile = await _profileRepository.getProfile(userId: _userId!);
      if (profile != null) {
        await _profileRepository.saveProfile(
          userId: _userId!,
          profile: profile.copyWith(notificationsEnabled: enabled),
        );
      }
      _notificationsEnabled = enabled;
      notifyListeners();
    } on ProfileRepositoryException catch (e) {
      _emitMessage('Failed to update notification preference: ${e.message}');
    }
  }

  Future<void> sendDemoNotification() async {
    try {
      await _notificationService.sendDemoNotification(
        title: 'Rift Detected Nearby',
        body: 'Explore a new location cell to transmute rare cards!',
      );
    } on StateError catch (e) {
      _emitMessage(e.message);
    }
  }

  void _emitMessage(String message) {
    if (!_messageController.isClosed) {
      _messageController.add(message);
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _messageController.close();
    super.dispose();
  }
}
