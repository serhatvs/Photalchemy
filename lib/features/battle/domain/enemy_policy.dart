import 'dart:math' as math;
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

  factory LegalEnemyAction.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final typeName = json['cardType'];
    final strength = json['strength'];
    final effectDescription = json['effectDescription'];

    if (id is! String ||
        typeName is! String ||
        strength is! int ||
        effectDescription is! String) {
      throw const FormatException('Missing or invalid LegalEnemyAction fields');
    }

    final CardType cardType;
    try {
      cardType = CardType.values.byName(typeName);
    } catch (_) {
      throw FormatException('Unknown CardType: $typeName');
    }

    return LegalEnemyAction(
      id: id,
      cardType: cardType,
      strength: strength,
      effectDescription: effectDescription,
    );
  }

  final String id;
  final CardType cardType;
  final int strength;
  final String effectDescription;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardType': cardType.name,
        'strength': strength,
        'effectDescription': effectDescription,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalEnemyAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          cardType == other.cardType &&
          strength == other.strength &&
          effectDescription == other.effectDescription;

  @override
  int get hashCode => Object.hash(id, cardType, strength, effectDescription);

  @override
  String toString() =>
      'LegalEnemyAction(id: $id, type: ${cardType.name}, strength: $strength)';
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

  factory EnemyObservation.fromJson(Map<String, dynamic> json) {
    final enemyHp = json['enemyHp'];
    final playerHp = json['playerHp'];
    final enemyShield = json['enemyShield'];
    final playerShield = json['playerShield'];
    final turnNumber = json['turnNumber'];
    final playerStunned = json['playerStunned'];
    final enemyStunned = json['enemyStunned'];
    final lastPlayerCardName = json['lastObservedPlayerCard'];
    final rawActions = json['legalActions'];

    if (enemyHp is! int ||
        playerHp is! int ||
        enemyShield is! int ||
        playerShield is! int ||
        turnNumber is! int ||
        playerStunned is! bool ||
        enemyStunned is! bool ||
        rawActions is! List) {
      throw const FormatException('Missing or invalid EnemyObservation fields');
    }

    CardType? lastObserved;
    if (lastPlayerCardName is String) {
      try {
        lastObserved = CardType.values.byName(lastPlayerCardName);
      } catch (_) {
        throw FormatException('Unknown CardType: $lastPlayerCardName');
      }
    }

    final actions = rawActions
        .map((a) =>
            LegalEnemyAction.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList();

    return EnemyObservation(
      enemyHp: enemyHp,
      playerHp: playerHp,
      enemyShield: enemyShield,
      playerShield: playerShield,
      turnNumber: turnNumber,
      playerStunned: playerStunned,
      enemyStunned: enemyStunned,
      lastObservedPlayerCard: lastObserved,
      legalActions: actions,
    );
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

  Map<String, dynamic> toJson() => {
        'enemyHp': enemyHp,
        'playerHp': playerHp,
        'enemyShield': enemyShield,
        'playerShield': playerShield,
        'turnNumber': turnNumber,
        'playerStunned': playerStunned,
        'enemyStunned': enemyStunned,
        if (lastObservedPlayerCard != null)
          'lastObservedPlayerCard': lastObservedPlayerCard!.name,
        'legalActions': legalActions.map((a) => a.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnemyObservation &&
          runtimeType == other.runtimeType &&
          enemyHp == other.enemyHp &&
          playerHp == other.playerHp &&
          enemyShield == other.enemyShield &&
          playerShield == other.playerShield &&
          turnNumber == other.turnNumber &&
          playerStunned == other.playerStunned &&
          enemyStunned == other.enemyStunned &&
          lastObservedPlayerCard == other.lastObservedPlayerCard &&
          _listEquals(legalActions, other.legalActions);

  static bool _listEquals(List<LegalEnemyAction> a, List<LegalEnemyAction> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        enemyHp,
        playerHp,
        enemyShield,
        playerShield,
        turnNumber,
        playerStunned,
        enemyStunned,
        lastObservedPlayerCard,
        Object.hashAll(legalActions),
      );
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

/// Deterministic random opponent baseline for Track A benchmarking.
class RandomEnemyPolicy implements EnemyPolicy {
  RandomEnemyPolicy({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    if (observation.legalActions.isEmpty) {
      throw StateError(
          'Cannot choose an action from an empty legal action set');
    }
    final index = _random.nextInt(observation.legalActions.length);
    return observation.legalActions[index].id;
  }
}

/// Deterministic, competitive rule-based heuristic opponent.
///
/// Baseline benchmark for Track A and fallback for Track B.
class HeuristicEnemyPolicy implements EnemyPolicy {
  const HeuristicEnemyPolicy();

  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    if (observation.legalActions.isEmpty) {
      throw StateError(
          'Cannot choose an action from an empty legal action set');
    }

    final actions = List<LegalEnemyAction>.from(observation.legalActions)
      ..sort((a, b) => a.id.compareTo(b.id));

    // 1. Check for lethal attack (deals >= effective player HP)
    final effectivePlayerHp = observation.playerHp + observation.playerShield;
    final lethal = actions.where((a) =>
        a.cardType == CardType.attack && a.strength >= effectivePlayerHp);
    if (lethal.isNotEmpty) {
      return lethal.first.id;
    }

    // 2. If low HP (< 5), prioritize survival: shield/defense or stun opponent
    if (observation.enemyHp < 5) {
      final defense = actions.where(
          (a) => a.cardType == CardType.defense || a.cardType == CardType.stun);
      if (defense.isNotEmpty) {
        defense.toList().sort((a, b) => b.strength.compareTo(a.strength));
        return defense.first.id;
      }
    }

    // 3. Otherwise pick the highest strength action available
    actions.sort((a, b) {
      final strengthCmp = b.strength.compareTo(a.strength);
      if (strengthCmp != 0) return strengthCmp;
      return a.id.compareTo(b.id);
    });

    return actions.first.id;
  }
}

/// Robust safety wrapper around an untrusted or experimental policy (such as Track B GenAI).
///
/// Enforces timeouts and validates chosen action IDs against the observation.
/// Falls back to [fallbackPolicy] on failure, timeout or hallucinated actions.
class SafeFallbackEnemyPolicy implements EnemyPolicy {
  SafeFallbackEnemyPolicy({
    required this.primaryPolicy,
    this.fallbackPolicy = const HeuristicEnemyPolicy(),
    this.timeout = const Duration(milliseconds: 1500),
  });

  final EnemyPolicy primaryPolicy;
  final EnemyPolicy fallbackPolicy;
  final Duration timeout;

  int _fallbackActivations = 0;
  int get fallbackActivations => _fallbackActivations;

  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    if (observation.legalActions.isEmpty) {
      return fallbackPolicy.chooseAction(observation);
    }

    try {
      final proposed =
          await primaryPolicy.chooseAction(observation).timeout(timeout);

      // Validate proposal against legal action set
      validateEnemyAction(observation, proposed);
      return proposed;
    } catch (_) {
      _fallbackActivations++;
      return fallbackPolicy.chooseAction(observation);
    }
  }
}
