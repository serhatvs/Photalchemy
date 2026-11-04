import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photalchemy/features/auth/presentation/account_page.dart';
import 'package:photalchemy/features/battle/domain/battle_engine.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/battle/presentation/battle_page.dart';
import 'package:photalchemy/features/cards/domain/card_generator.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/cards/domain/photo_analysis.dart';
import 'package:photalchemy/features/collection/presentation/collection_page.dart';
import 'package:photalchemy/features/exploration/presentation/explore_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isAuthenticated = false;
  String? _userEmail;

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

  void _handleExploreCapture() {
    final generator = const CardGenerator();
    final random = math.Random();
    final features = PhotoFeatures(
      brightness: (random.nextInt(80) + 20) / 100.0,
      saturation: (random.nextInt(80) + 20) / 100.0,
      contrast: (random.nextInt(80) + 20) / 100.0,
    );
    final cardId = 'card-${_collection.length + 1}';
    final card = generator.generate(
      id: cardId,
      ownerId: _isAuthenticated ? (_userEmail ?? 'player') : 'guest',
      features: features,
      rarity: CardRarity.values[random.nextInt(CardRarity.values.length)],
    );

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

  void _handleSignIn() {
    setState(() {
      _isAuthenticated = true;
      _userEmail = 'alchemist@photalchemy.io';
    });
  }

  void _handleSignOut() {
    setState(() {
      _isAuthenticated = false;
      _userEmail = null;
    });
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
        email: _userEmail,
        onSignIn: _handleSignIn,
        onSignOut: _handleSignOut,
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
