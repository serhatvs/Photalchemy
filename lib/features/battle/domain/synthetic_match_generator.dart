import 'dart:convert';
import 'package:photalchemy/features/battle/domain/battle_engine.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';

/// Single decision record matching ml/dataset_manifest_schema.csv.
class SyntheticDecisionRecord {
  const SyntheticDecisionRecord({
    required this.decisionId,
    required this.matchGroupId,
    required this.matchSeed,
    required this.rulesVersion,
    required this.opponentPolicy,
    required this.turnIndex,
    required this.enemyHp,
    required this.playerHp,
    required this.legalActionsJson,
    required this.actionId,
    required this.estimatedWinProbability,
    required this.split,
  });

  final String decisionId;
  final String matchGroupId;
  final int matchSeed;
  final String rulesVersion;
  final String opponentPolicy;
  final int turnIndex;
  final int enemyHp;
  final int playerHp;
  final String legalActionsJson;
  final String actionId;
  final double estimatedWinProbability;
  final String split; // 'train', 'validation', or 'test'

  String toCsvRow() {
    // Escape JSON string for CSV quoting
    final escapedJson = legalActionsJson.replaceAll('"', '""');
    return '$decisionId,$matchGroupId,$matchSeed,$rulesVersion,$opponentPolicy,'
        '$turnIndex,$enemyHp,$playerHp,"$escapedJson",$actionId,'
        '${estimatedWinProbability.toStringAsFixed(2)},$split';
  }
}

/// Generates reproducible synthetic battle trajectories for Track A offline policy training.
///
/// Prevents data leakage by ensuring entire match groups are assigned strictly to train or test.
class SyntheticMatchDatasetGenerator {
  const SyntheticMatchDatasetGenerator({
    this.rulesVersion = 'rules-v0',
    this.engine = const BattleEngine(),
  });

  final String rulesVersion;
  final BattleEngine engine;

  static const String csvHeader =
      'decision_id,match_group_id,match_seed,rules_version,opponent_policy,'
      'turn_index,enemy_hp,player_hp,legal_actions_json,action_id,'
      'estimated_win_probability,split';

  Future<List<SyntheticDecisionRecord>> generateMatchTrajectory({
    required String matchGroupId,
    required int matchSeed,
    required String split,
    required EnemyPolicy actingPolicy,
    required EnemyPolicy opponentPolicy,
    required String opponentPolicyName,
    required List<LegalEnemyAction> actingDeck,
    required List<LegalEnemyAction> opponentDeck,
    int initialHp = 10,
  }) async {
    final records = <_IntermediaryDecision>[];

    var state = BattleState(
      turnNumber: 1,
      player: BattleCombatant(
        hp: initialHp,
        maxHp: initialHp,
        shield: 0,
        isStunned: false,
      ),
      enemy: BattleCombatant(
        hp: initialHp,
        maxHp: initialHp,
        shield: 0,
        isStunned: false,
      ),
    );

    while (!state.isGameOver) {
      final actingObs = state.createObservation(legalActions: actingDeck);
      final oppObs = state.createObservation(legalActions: opponentDeck);

      final actingActionId = state.player.isStunned
          ? null
          : await actingPolicy.chooseAction(actingObs);
      final oppActionId = state.enemy.isStunned
          ? null
          : await opponentPolicy.chooseAction(oppObs);

      final pAction = actingActionId != null
          ? actingDeck.firstWhere((a) => a.id == actingActionId)
          : null;
      final eAction = oppActionId != null
          ? opponentDeck.firstWhere((a) => a.id == oppActionId)
          : null;

      if (pAction != null) {
        records.add(
          _IntermediaryDecision(
            decisionId: '$matchGroupId-s$matchSeed-t${state.turnNumber}',
            turnIndex: state.turnNumber,
            enemyHp: state.enemy.hp,
            playerHp: state.player.hp,
            legalActionsJson:
                jsonEncode(actingDeck.map((a) => a.toJson()).toList()),
            actionId: pAction.id,
          ),
        );
      }

      state = engine.resolveTurn(
        state: state,
        playerAction: pAction,
        enemyAction: eAction,
      );
    }

    // Outcome reward: 1.0 on victory, 0.0 on defeat, 0.5 on draw
    final outcomeReward = state.winner == CombatantSide.player
        ? 1.0
        : state.winner == CombatantSide.enemy
            ? 0.0
            : 0.5;

    return records
        .map(
          (d) => SyntheticDecisionRecord(
            decisionId: d.decisionId,
            matchGroupId: matchGroupId,
            matchSeed: matchSeed,
            rulesVersion: rulesVersion,
            opponentPolicy: opponentPolicyName,
            turnIndex: d.turnIndex,
            enemyHp: d.enemyHp,
            playerHp: d.playerHp,
            legalActionsJson: d.legalActionsJson,
            actionId: d.actionId,
            estimatedWinProbability: outcomeReward,
            split: split,
          ),
        )
        .toList();
  }
}

class _IntermediaryDecision {
  const _IntermediaryDecision({
    required this.decisionId,
    required this.turnIndex,
    required this.enemyHp,
    required this.playerHp,
    required this.legalActionsJson,
    required this.actionId,
  });

  final String decisionId;
  final int turnIndex;
  final int enemyHp;
  final int playerHp;
  final String legalActionsJson;
  final String actionId;
}
