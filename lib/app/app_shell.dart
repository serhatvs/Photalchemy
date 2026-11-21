import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photalchemy/core/notifications/notification_service.dart';
import 'package:photalchemy/core/storage/firestore_gateway.dart';
import 'package:photalchemy/features/auth/domain/auth_repository.dart';
import 'package:photalchemy/features/auth/domain/profile_repository.dart';
import 'package:photalchemy/features/auth/presentation/account_page.dart';
import 'package:photalchemy/features/battle/domain/battle_engine.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/battle/presentation/battle_page.dart';
import 'package:photalchemy/features/cards/data/firestore_card_repository.dart';
import 'package:photalchemy/features/cards/domain/card_generator.dart';
import 'package:photalchemy/features/cards/domain/card_repository.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/cards/domain/photo_analysis.dart';
import 'package:photalchemy/features/collection/presentation/collection_page.dart';
import 'package:photalchemy/features/exploration/domain/rarity_policy.dart';
import 'package:photalchemy/features/exploration/presentation/explore_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.authRepository,
    this.cardRepository,
    this.profileRepository,
    this.notificationService,
  });

  final AuthRepository? authRepository;
  final CardRepository? cardRepository;
  final ProfileRepository? profileRepository;
  final NotificationService? notificationService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AuthRepository _authRepository;
  late final CardRepository _cardRepository;
  late final ProfileRepository _profileRepository;
  late final NotificationService _notificationService;
  StreamSubscription<GameNotification>? _notificationSub;

  int _selectedIndex = 0;
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  bool _notificationsEnabled = false;

  final List<GameCard> _collection = [
    GameCard(
      id: 'starter-ember',
      ownerId: 'player',
      type: CardType.attack,
      rarity: CardRarity.common,
      stats: const CardStats(strength: 4),
      generationVersion: 'color-v0',
    ),
  ];

  BattleState _battleState = BattleState(
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

  static const _battleEngine = BattleEngine();
  static const _enemyPolicy = HeuristicEnemyPolicy();
  static const _rarityPolicy = RarityPolicy();
  static final _demoCell = CoarseLocation.fromCoordinates(38.7205, 35.4826);

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
  ];

  @override
  void initState() {
    super.initState();
    final gateway = RuleEnforcingInMemoryFirestoreGateway();
    _authRepository = widget.authRepository ?? MockAuthRepository();
    _cardRepository = widget.cardRepository ??
        FirestoreCardRepository(
          gateway: gateway,
          authenticatedUidProvider: () => _authRepository.currentUser?.id,
        );
    _profileRepository = widget.profileRepository ??
        FirestoreProfileRepository(
          gateway: gateway,
          authenticatedUidProvider: () => _authRepository.currentUser?.id,
        );
    _notificationService =
        widget.notificationService ?? MockFcmNotificationService();

    _notificationSub = _notificationService.onNotification.listen((msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('FCM [${msg.topic}]: ${msg.title} — ${msg.body}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _handleExploreCapture() async {
    final generator = const CardGenerator();
    final random = math.Random();
    final features = PhotoFeatures(
      brightness: (random.nextInt(80) + 20) / 100.0,
      saturation: (random.nextInt(80) + 20) / 100.0,
      contrast: (random.nextInt(80) + 20) / 100.0,
    );
    final cardId = 'card-${_collection.length + 1}';
    final ownerId = _isAuthenticated ? (_userId ?? 'player') : 'guest';

    Map<String, int> cellCounts = const {};
    if (_isAuthenticated && _userId != null) {
      final profile = await _profileRepository.getProfile(userId: _userId!);
      cellCounts = profile?.cellCaptureCounts ?? const {};
    }

    final rarity = _rarityPolicy.determineRarity(
      features: features,
      permission: LocationPermission.granted,
      location: _demoCell,
      cellCaptureCounts: cellCounts,
      random: random,
    );

    final card = generator.generate(
      id: cardId,
      ownerId: ownerId,
      features: features,
      rarity: rarity,
    );

    if (_isAuthenticated && _userId != null) {
      await _cardRepository.saveCard(userId: _userId!, card: card);
      await _profileRepository.incrementCellCapture(
        userId: _userId!,
        cellKey: _demoCell.cellKey,
      );
    }

    setState(() {
      _collection.insert(0, card);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synthesized ${card.type.name.toUpperCase()} card ($cardId)!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleBattleAction(LegalEnemyAction playerAction) async {
    if (_battleState.isGameOver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Battle is over! Resetting arena...')),
      );
      setState(() {
        _battleState = BattleState(
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
      });
      return;
    }

    final enemyObs =
        _battleState.createObservation(legalActions: _enemyActions);
    final enemyActionId = await _enemyPolicy.chooseAction(enemyObs);
    final enemyAction = _enemyActions.firstWhere((a) => a.id == enemyActionId);

    final nextState = _battleEngine.resolveTurn(
      state: _battleState,
      playerAction: playerAction,
      enemyAction: enemyAction,
    );

    setState(() {
      _battleState = nextState;
    });

    if (nextState.isGameOver && mounted) {
      final winnerText = nextState.winner == CombatantSide.player
          ? '🎉 Victory! Player defeated the enemy!'
          : nextState.winner == CombatantSide.enemy
              ? '💀 Defeat! Player was defeated!'
              : '🤝 Draw match!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(winnerText)),
      );
    }
  }

  Future<void> _handleSignIn() async {
    final user = await _authRepository.signInWithGoogle();
    final existingProfile =
        await _profileRepository.getProfile(userId: user.id);
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

    setState(() {
      _isAuthenticated = true;
      _userId = user.id;
      _userEmail = user.email;
      _notificationsEnabled = existingProfile?.notificationsEnabled ?? false;
    });
  }

  Future<void> _handleSignOut() async {
    await _authRepository.signOut();
    setState(() {
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _notificationsEnabled = false;
    });
  }

  Future<void> _handleToggleNotifications(bool enabled) async {
    if (!_isAuthenticated || _userId == null) return;
    if (enabled) {
      final status = await _notificationService.requestPermission();
      if (status != NotificationPermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission denied.'),
            ),
          );
        }
        return;
      }
      await _notificationService.subscribeToTopic('dungeon_alerts');
    } else {
      await _notificationService.unsubscribeFromTopic('dungeon_alerts');
    }

    final profile = await _profileRepository.getProfile(userId: _userId!);
    if (profile != null) {
      await _profileRepository.saveProfile(
        userId: _userId!,
        profile: profile.copyWith(notificationsEnabled: enabled),
      );
    }

    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _handleSendDemoNotification() async {
    await _notificationService.sendDemoNotification(
      title: 'Rift Detected Nearby',
      body: 'Explore a new location cell to transmute rare cards!',
    );
  }

  List<Widget> _buildPages() {
    return [
      ExplorePage(onCapture: _handleExploreCapture),
      CollectionPage(cards: _collection),
      BattlePage(
        enemyHp: _battleState.enemy.hp,
        maxEnemyHp: _battleState.enemy.maxHp,
        enemyShield: _battleState.enemy.shield,
        playerHp: _battleState.player.hp,
        maxPlayerHp: _battleState.player.maxHp,
        playerShield: _battleState.player.shield,
        turnNumber: _battleState.turnNumber,
        legalActions: _playerActions,
        onActionSelected: _handleBattleAction,
      ),
      AccountPage(
        isAuthenticated: _isAuthenticated,
        userId: _userId,
        email: _userEmail,
        notificationsEnabled: _notificationsEnabled,
        onSignIn: _handleSignIn,
        onSignOut: _handleSignOut,
        onToggleNotifications: _handleToggleNotifications,
        onSendDemoNotification: _handleSendDemoNotification,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photalchemy')),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _buildPages(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Battle',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
