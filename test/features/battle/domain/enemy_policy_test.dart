import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

class _FailingPolicy implements EnemyPolicy {
  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    throw Exception('Simulated network/provider error');
  }
}

class _HallucinatingPolicy implements EnemyPolicy {
  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    return 'non-existent-cheat-card';
  }
}

class _HangingPolicy implements EnemyPolicy {
  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    await Completer<void>().future; // Never completes
    return 'never';
  }
}

void main() {
  test('legal move is validated by server/game engine boundary', () {
    final attack = LegalEnemyAction(
      id: 'play-attack',
      cardType: CardType.attack,
      strength: 4,
      effectDescription: 'Deal damage according to battle rules.',
    );
    final observation = EnemyObservation(
      enemyHp: 8,
      playerHp: 4,
      enemyShield: 0,
      playerShield: 0,
      turnNumber: 1,
      playerStunned: false,
      enemyStunned: false,
      legalActions: [attack],
    );
    expect(validateEnemyAction(observation, 'play-attack'), same(attack));
    expect(observation.turnNumber, 1);
    expect(
      () => validateEnemyAction(observation, 'make-me-invincible'),
      throwsArgumentError,
    );
  });

  test('observation rejects invalid and duplicate legal actions', () {
    LegalEnemyAction attack(String id) => LegalEnemyAction(
          id: id,
          cardType: CardType.attack,
          strength: 4,
          effectDescription: 'Attack enemy.',
        );
    expect(
      () => EnemyObservation(
        enemyHp: -1,
        playerHp: 10,
        enemyShield: 0,
        playerShield: 0,
        turnNumber: 1,
        playerStunned: false,
        enemyStunned: false,
        legalActions: [attack('a')],
      ),
      throwsRangeError,
    );
    expect(
      () => EnemyObservation(
        enemyHp: 10,
        playerHp: 10,
        enemyShield: 0,
        playerShield: 0,
        turnNumber: 1,
        playerStunned: false,
        enemyStunned: false,
        legalActions: [attack('a'), attack('a')],
      ),
      throwsArgumentError,
    );
    expect(
      () => attack(''),
      throwsArgumentError,
    );
  });

  test('legal actions are snapshot-owned and immutable', () {
    final external = <LegalEnemyAction>[];
    final observation = EnemyObservation(
      enemyHp: 10,
      playerHp: 10,
      enemyShield: 0,
      playerShield: 0,
      turnNumber: 1,
      playerStunned: false,
      enemyStunned: false,
      legalActions: external,
    );
    external.add(
      LegalEnemyAction(
        id: 'later',
        cardType: CardType.stun,
        strength: 1,
        effectDescription: 'Apply stun.',
      ),
    );
    expect(observation.legalActions, isEmpty);
    expect(
      () => observation.legalActions.add(external.first),
      throwsUnsupportedError,
    );
  });

  test('LegalEnemyAction and EnemyObservation JSON roundtrip', () {
    final action = LegalEnemyAction(
      id: 'act-1',
      cardType: CardType.stun,
      strength: 6,
      effectDescription: 'Stun opponent for 1 turn.',
    );
    final actionJson = action.toJson();
    final restoredAction = LegalEnemyAction.fromJson(actionJson);
    expect(restoredAction, equals(action));
    expect(restoredAction.hashCode, equals(action.hashCode));

    final obs = EnemyObservation(
      enemyHp: 15,
      playerHp: 8,
      enemyShield: 2,
      playerShield: 1,
      turnNumber: 3,
      playerStunned: true,
      enemyStunned: false,
      lastObservedPlayerCard: CardType.reflect,
      legalActions: [action],
    );

    final obsJson = obs.toJson();
    final restoredObs = EnemyObservation.fromJson(obsJson);
    expect(restoredObs, equals(obs));
    expect(restoredObs.hashCode, equals(obs.hashCode));
  });

  test('RandomEnemyPolicy selects an action from legal set', () async {
    final a1 = LegalEnemyAction(
      id: 'a1',
      cardType: CardType.attack,
      strength: 3,
      effectDescription: 'Atk',
    );
    final a2 = LegalEnemyAction(
      id: 'a2',
      cardType: CardType.defense,
      strength: 3,
      effectDescription: 'Def',
    );
    final obs = EnemyObservation(
      enemyHp: 10,
      playerHp: 10,
      enemyShield: 0,
      playerShield: 0,
      turnNumber: 1,
      playerStunned: false,
      enemyStunned: false,
      legalActions: [a1, a2],
    );

    final policy = RandomEnemyPolicy(random: math.Random(42));
    final choice = await policy.chooseAction(obs);
    expect(choice, anyOf(['a1', 'a2']));
  });

  test('HeuristicEnemyPolicy prioritizes lethal strike', () async {
    final poke = LegalEnemyAction(
      id: 'poke',
      cardType: CardType.attack,
      strength: 2,
      effectDescription: 'Small hit',
    );
    final finisher = LegalEnemyAction(
      id: 'finisher',
      cardType: CardType.attack,
      strength: 5,
      effectDescription: 'Lethal hit',
    );
    final obs = EnemyObservation(
      enemyHp: 10,
      playerHp: 5,
      enemyShield: 0,
      playerShield: 0,
      turnNumber: 2,
      playerStunned: false,
      enemyStunned: false,
      legalActions: [poke, finisher],
    );

    const policy = HeuristicEnemyPolicy();
    final choice = await policy.chooseAction(obs);
    expect(choice, 'finisher');
  });

  test('HeuristicEnemyPolicy prioritizes defense when HP is critically low',
      () async {
    final strongAttack = LegalEnemyAction(
      id: 'big-atk',
      cardType: CardType.attack,
      strength: 8,
      effectDescription: 'High damage',
    );
    final shield = LegalEnemyAction(
      id: 'shield',
      cardType: CardType.defense,
      strength: 6,
      effectDescription: 'Raise defense',
    );
    final obs = EnemyObservation(
      enemyHp: 3, // Low health
      playerHp: 20,
      enemyShield: 0,
      playerShield: 0,
      turnNumber: 4,
      playerStunned: false,
      enemyStunned: false,
      legalActions: [strongAttack, shield],
    );

    const policy = HeuristicEnemyPolicy();
    final choice = await policy.chooseAction(obs);
    expect(choice, 'shield');
  });

  test(
      'SafeFallbackEnemyPolicy handles primary policy failures, hallucinations and timeouts',
      () async {
    final safeAction = LegalEnemyAction(
      id: 'safe-def',
      cardType: CardType.defense,
      strength: 5,
      effectDescription: 'Defend',
    );
    final obs = EnemyObservation(
      enemyHp: 10,
      playerHp: 10,
      enemyShield: 0,
      playerShield: 0,
      turnNumber: 1,
      playerStunned: false,
      enemyStunned: false,
      legalActions: [safeAction],
    );

    // 1. Crash fallback
    final crashFallback = SafeFallbackEnemyPolicy(
      primaryPolicy: _FailingPolicy(),
    );
    expect(await crashFallback.chooseAction(obs), 'safe-def');
    expect(crashFallback.fallbackActivations, 1);

    // 2. Hallucination fallback
    final hallucinationFallback = SafeFallbackEnemyPolicy(
      primaryPolicy: _HallucinatingPolicy(),
    );
    expect(await hallucinationFallback.chooseAction(obs), 'safe-def');
    expect(hallucinationFallback.fallbackActivations, 1);

    // 3. Timeout fallback
    final timeoutFallback = SafeFallbackEnemyPolicy(
      primaryPolicy: _HangingPolicy(),
      timeout: const Duration(milliseconds: 50),
    );
    expect(await timeoutFallback.chooseAction(obs), 'safe-def');
    expect(timeoutFallback.fallbackActivations, 1);
  });
}
