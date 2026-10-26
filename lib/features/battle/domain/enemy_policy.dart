import 'package:photalchemy/features/cards/domain/game_card.dart';

/// Only information an opponent may legally observe is included here.
/// No hidden player hand, deck order, credentials, photos or exact locations.
class LegalEnemyAction {
  LegalEnemyAction({
    required this.id,
    required this.cardType,
    required this.strength,
    required this.effectDescription,
  }) {
    if (id.trim().isEmpty || effectDescription.trim().isEmpty) {
      throw ArgumentError('Action id and effect description must be nonempty');
    }
    RangeError.checkValueInInterval(strength, 1, 10, 'strength');
  }

  final String id;
  final CardType cardType;
  final int strength;
  final String effectDescription;
}

/// Snapshot contract shared by trained Track A and tool-calling Track B.
///
/// The real battle engine and exact effect semantics are Kadir's work.
class EnemyObservation {
  EnemyObservation({
    required this.enemyHp,
    required this.playerHp,
    required this.enemyShield,
    required this.playerShield,
    required this.turnNumber,
    required this.playerStunned,
    required this.enemyStunned,
    this.lastObservedPlayerCard,
    required List<LegalEnemyAction> legalActions,
  }) : legalActions = List.unmodifiable(legalActions) {
    if (enemyHp < 0 ||
        playerHp < 0 ||
        enemyShield < 0 ||
        playerShield < 0 ||
        turnNumber < 0) {
      throw RangeError('Health and shield values must be nonnegative');
    }
    if (this.legalActions.map((a) => a.id).toSet().length !=
        this.legalActions.length) {
      throw ArgumentError('Duplicate legal action identifiers');
    }
  }

  final int enemyHp;
  final int playerHp;
  final int enemyShield;
  final int playerShield;
  final int turnNumber;
  final bool playerStunned;
  final bool enemyStunned;
  final CardType? lastObservedPlayerCard;
  final List<LegalEnemyAction> legalActions;
}

/// An opponent selects an action; it does NOT change the game state.
///
/// Track A: train an action scorer from simulated battles.
/// Track B: generative tool-calling agent with 20+ evaluation scenarios.
abstract class EnemyPolicy {
  Future<String> chooseAction(EnemyObservation observation);
}

/// Game engine must call this before applying any proposed model action.
/// Reject hallucinated/invalid IDs, including AI-generated tool output.
LegalEnemyAction validateEnemyAction(
  EnemyObservation observation,
  String proposedActionId,
) {
  for (final action in observation.legalActions) {
    if (action.id == proposedActionId) return action;
  }
  throw ArgumentError.value(
    proposedActionId,
    'proposedActionId',
    'Not in the permitted action set',
  );
}
