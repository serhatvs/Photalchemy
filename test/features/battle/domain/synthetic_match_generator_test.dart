import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/battle/domain/synthetic_match_generator.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

void main() {
  const generator = SyntheticMatchDatasetGenerator();

  final deck = [
    LegalEnemyAction(
      id: 'atk-3',
      cardType: CardType.attack,
      strength: 3,
      effectDescription: 'Deal 3 damage',
    ),
    LegalEnemyAction(
      id: 'def-2',
      cardType: CardType.defense,
      strength: 2,
      effectDescription: 'Gain 2 shield',
    ),
  ];

  test('csvHeader matches dataset_manifest_schema.csv specification', () {
    const expected =
        'decision_id,match_group_id,match_seed,rules_version,opponent_policy,'
        'turn_index,enemy_hp,player_hp,legal_actions_json,action_id,'
        'estimated_win_probability,split';
    expect(SyntheticMatchDatasetGenerator.csvHeader, equals(expected));
  });

  test('generates valid trajectory records from simulated match', () async {
    final trajectory = await generator.generateMatchTrajectory(
      matchGroupId: 'group-alpha',
      matchSeed: 101,
      split: 'train',
      actingPolicy: const HeuristicEnemyPolicy(),
      opponentPolicy: RandomEnemyPolicy(random: math.Random(101)),
      opponentPolicyName: 'random_baseline',
      actingDeck: deck,
      opponentDeck: deck,
      initialHp: 6,
    );

    expect(trajectory, isNotEmpty);

    for (final record in trajectory) {
      expect(record.matchGroupId, 'group-alpha');
      expect(record.matchSeed, 101);
      expect(record.split, 'train');
      expect(record.opponentPolicy, 'random_baseline');
      expect(record.rulesVersion, 'rules-v0');
      expect(record.turnIndex, greaterThanOrEqualTo(1));
      expect(record.actionId, anyOf(['atk-3', 'def-2']));
      expect(record.estimatedWinProbability, isIn([0.0, 0.5, 1.0]));

      // Check legal actions JSON is valid JSON
      final parsedJson = jsonDecode(record.legalActionsJson);
      expect(parsedJson, isA<List>());

      // Check CSV row format
      final csvRow = record.toCsvRow();
      expect(csvRow, contains('group-alpha'));
      expect(csvRow, contains('rules-v0'));
      expect(csvRow, contains('train'));
    }
  });

  test('group split isolation assigns distinct group IDs to distinct splits',
      () async {
    final trainTrajectory = await generator.generateMatchTrajectory(
      matchGroupId: 'group-001',
      matchSeed: 1,
      split: 'train',
      actingPolicy: const HeuristicEnemyPolicy(),
      opponentPolicy: const HeuristicEnemyPolicy(),
      opponentPolicyName: 'heuristic',
      actingDeck: deck,
      opponentDeck: deck,
      initialHp: 4,
    );

    final testTrajectory = await generator.generateMatchTrajectory(
      matchGroupId: 'group-002',
      matchSeed: 2,
      split: 'test',
      actingPolicy: const HeuristicEnemyPolicy(),
      opponentPolicy: const HeuristicEnemyPolicy(),
      opponentPolicyName: 'heuristic',
      actingDeck: deck,
      opponentDeck: deck,
      initialHp: 4,
    );

    final trainGroupIds = trainTrajectory.map((r) => r.matchGroupId).toSet();
    final testGroupIds = testTrajectory.map((r) => r.matchGroupId).toSet();

    // Zero overlap between group IDs across splits (anti-data-leakage)
    expect(trainGroupIds.intersection(testGroupIds), isEmpty);
  });
}
