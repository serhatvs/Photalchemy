import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

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
}
