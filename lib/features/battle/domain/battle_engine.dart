import 'dart:math' as math;
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

enum CombatantSide { player, enemy, draw }

/// State of a combatant (player or enemy AI).
class BattleCombatant {
  const BattleCombatant({
    required this.hp,
    required this.maxHp,
    required this.shield,
    required this.isStunned,
  })  : assert(hp >= 0, 'HP must be nonnegative'),
        assert(maxHp > 0, 'Max HP must be positive'),
        assert(shield >= 0, 'Shield must be nonnegative');

  final int hp;
  final int maxHp;
  final int shield;
  final bool isStunned;

  bool get isDefeated => hp <= 0;

  BattleCombatant copyWith({
    int? hp,
    int? maxHp,
    int? shield,
    bool? isStunned,
  }) {
    return BattleCombatant(
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      shield: shield ?? this.shield,
      isStunned: isStunned ?? this.isStunned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BattleCombatant &&
          runtimeType == other.runtimeType &&
          hp == other.hp &&
          maxHp == other.maxHp &&
          shield == other.shield &&
          isStunned == other.isStunned;

  @override
  int get hashCode => Object.hash(hp, maxHp, shield, isStunned);

  @override
  String toString() =>
      'Combatant(HP: $hp/$maxHp, Shield: $shield, Stunned: $isStunned)';
}

/// Recorded outcome of a single turn resolution.
class TurnResult {
  const TurnResult({
    required this.turnNumber,
    required this.playerAction,
    required this.enemyAction,
    required this.damageToPlayer,
    required this.damageToEnemy,
    required this.playerShieldAbsorbed,
    required this.enemyShieldAbsorbed,
    required this.playerStunned,
    required this.enemyStunned,
    required this.summary,
  });

  final int turnNumber;
  final LegalEnemyAction? playerAction;
  final LegalEnemyAction? enemyAction;
  final int damageToPlayer;
  final int damageToEnemy;
  final int playerShieldAbsorbed;
  final int enemyShieldAbsorbed;
  final bool playerStunned;
  final bool enemyStunned;
  final String summary;

  @override
  String toString() => 'Turn $turnNumber: $summary';
}

/// Full game state of an active or concluded battle.
class BattleState {
  BattleState({
    required this.turnNumber,
    required this.player,
    required this.enemy,
    this.lastPlayerCardType,
    List<TurnResult>? history,
  }) : history = List.unmodifiable(history ?? const []);

  final int turnNumber;
  final BattleCombatant player;
  final BattleCombatant enemy;
  final CardType? lastPlayerCardType;
  final List<TurnResult> history;

  bool get isGameOver =>
      player.isDefeated || enemy.isDefeated || turnNumber > maxAllowedTurns;

  static const int maxAllowedTurns = 50;

  CombatantSide? get winner {
    if (!isGameOver) return null;
    if (player.isDefeated && enemy.isDefeated) return CombatantSide.draw;
    if (player.isDefeated) return CombatantSide.enemy;
    if (enemy.isDefeated) return CombatantSide.player;
    // Tie-break turn limit reached: highest remaining HP wins
    if (player.hp > enemy.hp) return CombatantSide.player;
    if (enemy.hp > player.hp) return CombatantSide.enemy;
    return CombatantSide.draw;
  }

  /// Exports an immutable snapshot that an enemy AI policy may observe legally.
  EnemyObservation createObservation({
    required List<LegalEnemyAction> legalActions,
  }) {
    return EnemyObservation(
      enemyHp: enemy.hp,
      playerHp: player.hp,
      enemyShield: enemy.shield,
      playerShield: player.shield,
      turnNumber: turnNumber,
      playerStunned: player.isStunned,
      enemyStunned: enemy.isStunned,
      lastObservedPlayerCard: lastPlayerCardType,
      legalActions: legalActions,
    );
  }
}

/// Deterministic combat rules engine.
///
/// Implements simultaneous card resolution, defense shielding, damage calculations,
/// stun application and infinite-reflect prevention according to QUALITY.md.
class BattleEngine {
  const BattleEngine();

  /// Resolves one turn between player and enemy actions deterministically.
  BattleState resolveTurn({
    required BattleState state,
    LegalEnemyAction? playerAction,
    LegalEnemyAction? enemyAction,
  }) {
    if (state.isGameOver) {
      throw StateError('Cannot resolve turn on an already finished battle');
    }

    var playerHp = state.player.hp;
    var playerShield = state.player.shield;
    var enemyHp = state.enemy.hp;
    var enemyShield = state.enemy.shield;

    // Effective actions: stunned combatants cannot act
    final effectivePlayerAction = state.player.isStunned ? null : playerAction;
    final effectiveEnemyAction = state.enemy.isStunned ? null : enemyAction;

    // 1. Process Defense actions first (adds shields before attacks land)
    if (effectivePlayerAction?.cardType == CardType.defense) {
      playerShield += effectivePlayerAction!.strength;
    }
    if (effectiveEnemyAction?.cardType == CardType.defense) {
      enemyShield += effectiveEnemyAction!.strength;
    }

    // 2. Calculate raw incoming attacks
    var rawDamageToEnemy = 0;
    var rawDamageToPlayer = 0;

    if (effectivePlayerAction?.cardType == CardType.attack) {
      rawDamageToEnemy += effectivePlayerAction!.strength;
    }
    if (effectiveEnemyAction?.cardType == CardType.attack) {
      rawDamageToPlayer += effectiveEnemyAction!.strength;
    }

    // 3. Process Reflect actions
    // Edge case from TESTING.md: prevent infinite reflect loops if both play reflect
    final playerReflects = effectivePlayerAction?.cardType == CardType.reflect;
    final enemyReflects = effectiveEnemyAction?.cardType == CardType.reflect;

    if (playerReflects && enemyReflects) {
      // Both reflect: reflections cancel each other out safely; no looping.
      rawDamageToPlayer = 0;
      rawDamageToEnemy = 0;
    } else {
      if (playerReflects && rawDamageToPlayer > 0) {
        // Player reflects incoming attack back to enemy
        rawDamageToEnemy += rawDamageToPlayer;
        rawDamageToPlayer = 0;
      }
      if (enemyReflects && rawDamageToEnemy > 0) {
        // Enemy reflects incoming attack back to player
        rawDamageToPlayer += rawDamageToEnemy;
        rawDamageToEnemy = 0;
      }
    }

    // 4. Apply damage through shields to HP (ensuring non-negative HP)
    final playerShieldAbsorbed = math.min(playerShield, rawDamageToPlayer);
    playerShield -= playerShieldAbsorbed;
    final finalDamageToPlayer = rawDamageToPlayer - playerShieldAbsorbed;
    playerHp = math.max(0, playerHp - finalDamageToPlayer);

    final enemyShieldAbsorbed = math.min(enemyShield, rawDamageToEnemy);
    enemyShield -= enemyShieldAbsorbed;
    final finalDamageToEnemy = rawDamageToEnemy - enemyShieldAbsorbed;
    enemyHp = math.max(0, enemyHp - finalDamageToEnemy);

    // 5. Determine Stun for NEXT turn
    // Stun only applies if the stunner was not stunned, and the target is not already defeated
    final nextEnemyStunned =
        effectivePlayerAction?.cardType == CardType.stun && enemyHp > 0;
    final nextPlayerStunned =
        effectiveEnemyAction?.cardType == CardType.stun && playerHp > 0;

    // 6. Record turn history and summary
    final summary = 'Turn ${state.turnNumber}: '
        'Player did ${effectivePlayerAction?.id ?? "Pass"} (took $finalDamageToPlayer dmg), '
        'Enemy did ${effectiveEnemyAction?.id ?? "Pass"} (took $finalDamageToEnemy dmg)';

    final turnResult = TurnResult(
      turnNumber: state.turnNumber,
      playerAction: effectivePlayerAction,
      enemyAction: effectiveEnemyAction,
      damageToPlayer: finalDamageToPlayer,
      damageToEnemy: finalDamageToEnemy,
      playerShieldAbsorbed: playerShieldAbsorbed,
      enemyShieldAbsorbed: enemyShieldAbsorbed,
      playerStunned: nextPlayerStunned,
      enemyStunned: nextEnemyStunned,
      summary: summary,
    );

    return BattleState(
      turnNumber: state.turnNumber + 1,
      player: state.player.copyWith(
        hp: playerHp,
        shield: playerShield,
        isStunned: nextPlayerStunned,
      ),
      enemy: state.enemy.copyWith(
        hp: enemyHp,
        shield: enemyShield,
        isStunned: nextEnemyStunned,
      ),
      lastPlayerCardType: effectivePlayerAction?.cardType,
      history: [...state.history, turnResult],
    );
  }

  /// Deterministically simulates a match between two AI policies up to conclusion.
  Future<BattleState> simulateMatch({
    required BattleState initialState,
    required EnemyPolicy playerPolicy,
    required EnemyPolicy enemyPolicy,
    required List<LegalEnemyAction> playerDeck,
    required List<LegalEnemyAction> enemyDeck,
  }) async {
    var state = initialState;

    while (!state.isGameOver) {
      final playerObs = state.createObservation(legalActions: playerDeck);
      final enemyObs = state.createObservation(legalActions: enemyDeck);

      final playerId = state.player.isStunned
          ? null
          : await playerPolicy.chooseAction(playerObs);
      final enemyId = state.enemy.isStunned
          ? null
          : await enemyPolicy.chooseAction(enemyObs);

      final pAction = playerId != null
          ? playerDeck.firstWhere((a) => a.id == playerId)
          : null;
      final eAction =
          enemyId != null ? enemyDeck.firstWhere((a) => a.id == enemyId) : null;

      state = resolveTurn(
        state: state,
        playerAction: pAction,
        enemyAction: eAction,
      );
    }

    return state;
  }
}
