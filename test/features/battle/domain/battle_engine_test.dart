import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/battle/domain/battle_engine.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

void main() {
  const engine = BattleEngine();

  LegalEnemyAction action(String id, CardType type, int strength) {
    return LegalEnemyAction(
      id: id,
      cardType: type,
      strength: strength,
      effectDescription: 'Effect $id',
    );
  }

  BattleState createState({
    int playerHp = 10,
    int enemyHp = 10,
    int playerShield = 0,
    int enemyShield = 0,
    bool playerStunned = false,
    bool enemyStunned = false,
  }) {
    return BattleState(
      turnNumber: 1,
      player: BattleCombatant(
        hp: playerHp,
        maxHp: 10,
        shield: playerShield,
        isStunned: playerStunned,
      ),
      enemy: BattleCombatant(
        hp: enemyHp,
        maxHp: 10,
        shield: enemyShield,
        isStunned: enemyStunned,
      ),
    );
  }

  test('shields absorb attack damage before reducing HP', () {
    final state = createState(enemyHp: 10, enemyShield: 4);
    final playerAtk = action('strike', CardType.attack, 6);

    final next = engine.resolveTurn(
      state: state,
      playerAction: playerAtk,
      enemyAction: null,
    );

    expect(next.enemy.shield, 0);
    expect(next.enemy.hp, 8);
    expect(next.turnNumber, 2);
    expect(next.history.first.enemyShieldAbsorbed, 4);
    expect(next.history.first.damageToEnemy, 2);
  });

  test('HP never drops below zero and game ends on defeat', () {
    final state = createState(enemyHp: 3);
    final overkill = action('nuke', CardType.attack, 10);

    final next = engine.resolveTurn(
      state: state,
      playerAction: overkill,
      enemyAction: null,
    );

    expect(next.enemy.hp, 0);
    expect(next.isGameOver, isTrue);
    expect(next.winner, CombatantSide.player);

    expect(
      () => engine.resolveTurn(state: next, playerAction: overkill),
      throwsStateError,
    );
  });

  test('reflect redirects attack damage back to attacker', () {
    final state = createState(playerHp: 10, enemyHp: 10);
    final enemyAttack = action('enemy-hit', CardType.attack, 5);
    final playerReflect = action('mirror', CardType.reflect, 5);

    final next = engine.resolveTurn(
      state: state,
      playerAction: playerReflect,
      enemyAction: enemyAttack,
    );

    expect(next.player.hp, 10);
    expect(next.enemy.hp, 5);
  });

  test('double reflect cancels out without infinite loop', () {
    final state = createState(playerHp: 10, enemyHp: 10);
    final playerReflect = action('p-mirror', CardType.reflect, 5);
    final enemyReflect = action('e-mirror', CardType.reflect, 5);

    final next = engine.resolveTurn(
      state: state,
      playerAction: playerReflect,
      enemyAction: enemyReflect,
    );

    expect(next.player.hp, 10);
    expect(next.enemy.hp, 10);
  });

  test('defense adds shield and absorbs incoming attack on same turn', () {
    final state = createState(playerHp: 10, enemyHp: 10);
    final playerDefense = action('guard', CardType.defense, 4);
    final enemyAttack = action('slash', CardType.attack, 5);

    final next = engine.resolveTurn(
      state: state,
      playerAction: playerDefense,
      enemyAction: enemyAttack,
    );

    expect(next.player.shield, 0);
    expect(next.player.hp, 9);
  });

  test('stun applies for exactly one turn and expires at turn boundary', () {
    final state = createState(playerHp: 10, enemyHp: 10);
    final playerStun = action('shock', CardType.stun, 3);
    final enemyAttack = action('slam', CardType.attack, 3);

    final turn2 = engine.resolveTurn(
      state: state,
      playerAction: playerStun,
      enemyAction: enemyAttack,
    );
    expect(turn2.enemy.isStunned, isTrue);

    final enemyAttemptedMove = action('attempt', CardType.attack, 4);
    final playerRegular = action('poke', CardType.attack, 2);

    final turn3 = engine.resolveTurn(
      state: turn2,
      playerAction: playerRegular,
      enemyAction: enemyAttemptedMove,
    );

    expect(turn3.player.hp, 7);
    expect(turn3.enemy.hp, 8);
    expect(turn3.enemy.isStunned, isFalse);
  });

  test('simulateMatch completes deterministically with two policies', () async {
    final deckA = [
      action('a-strike', CardType.attack, 3),
      action('a-guard', CardType.defense, 2),
      action('a-stun', CardType.stun, 1),
    ];
    final deckB = [
      action('b-strike', CardType.attack, 2),
      action('b-guard', CardType.defense, 3),
    ];

    final finalState = await engine.simulateMatch(
      initialState: createState(playerHp: 8, enemyHp: 8),
      playerPolicy: const HeuristicEnemyPolicy(),
      enemyPolicy: RandomEnemyPolicy(random: math.Random(1337)),
      playerDeck: deckA,
      enemyDeck: deckB,
    );

    expect(finalState.isGameOver, isTrue);
    expect(finalState.winner, isNotNull);
    expect(finalState.history, isNotEmpty);
  });

  test('HP tie-break correctly determines winner on max turns reached', () {
    const playerHighHp =
        BattleCombatant(hp: 9, maxHp: 10, shield: 0, isStunned: false);
    const enemyLowHp =
        BattleCombatant(hp: 4, maxHp: 10, shield: 0, isStunned: false);
    final finishedState = BattleState(
      turnNumber: 51,
      player: playerHighHp,
      enemy: enemyLowHp,
    );

    expect(finishedState.isGameOver, isTrue);
    expect(finishedState.winner, CombatantSide.player);
  });

  test('negative damage protection clamps lethal incoming attack to zero HP',
      () {
    final state = createState(playerHp: 2, playerShield: 2);
    final lethalHit = action('massive-hit', CardType.attack, 10);

    final next = engine.resolveTurn(
      state: state,
      playerAction: null,
      enemyAction: lethalHit,
    );

    expect(next.player.shield, 0);
    expect(next.player.hp, 0);
    expect(next.player.isDefeated, isTrue);
    expect(next.isGameOver, isTrue);
    expect(next.winner, CombatantSide.enemy);
  });
}
