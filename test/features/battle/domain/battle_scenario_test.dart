import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/features/battle/domain/battle_scenario.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

class _HangingPolicy implements EnemyPolicy {
  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    final completer = Completer<String>();
    // Never completes
    return completer.future;
  }
}

class _HallucinatingPolicy implements EnemyPolicy {
  @override
  Future<String> chooseAction(EnemyObservation observation) async {
    return 'non_existent_hallucinated_card_id';
  }
}

void main() {
  group('BattleScenario and EvaluationRunner', () {
    test(
        'PredefinedScenarios contains exactly 20 scenarios across diverse categories',
        () {
      final scenarios = PredefinedScenarios.all20;
      expect(scenarios.length, 20);

      final categories = scenarios.map((s) => s.category).toSet();
      expect(categories, contains(ScenarioCategory.tactics));
      expect(categories, contains(ScenarioCategory.boundary));
      expect(categories, contains(ScenarioCategory.adversarial));

      // Unique IDs
      final ids = scenarios.map((s) => s.id).toSet();
      expect(ids.length, 20);
    });

    test('BattleScenario single-case evaluation boundaries', () {
      final observation = EnemyObservation(
        enemyHp: 10,
        playerHp: 5,
        enemyShield: 0,
        playerShield: 0,
        turnNumber: 1,
        playerStunned: false,
        enemyStunned: false,
        legalActions: [
          LegalEnemyAction(
            id: 'atk-1',
            cardType: CardType.attack,
            strength: 5,
            effectDescription: 'Atk',
          ),
          LegalEnemyAction(
            id: 'def-1',
            cardType: CardType.defense,
            strength: 4,
            effectDescription: 'Def',
          ),
        ],
      );

      final scenarioExact = BattleScenario(
        id: 'TEST-1',
        title: 'Exact match',
        category: ScenarioCategory.tactics,
        observation: observation,
        expectedActionId: 'atk-1',
      );

      expect(scenarioExact.evaluate('atk-1'), isTrue);
      expect(scenarioExact.evaluate('def-1'), isFalse);
      expect(scenarioExact.evaluate('hallucinated'), isFalse);

      final scenarioType = BattleScenario(
        id: 'TEST-2',
        title: 'Type match',
        category: ScenarioCategory.tactics,
        observation: observation,
        expectedCardType: CardType.defense,
      );

      expect(scenarioType.evaluate('def-1'), isTrue);
      expect(scenarioType.evaluate('atk-1'), isFalse);

      final scenarioCustom = BattleScenario(
        id: 'TEST-3',
        title: 'Custom validator',
        category: ScenarioCategory.tactics,
        observation: observation,
        customValidator: (id, obs) => id.startsWith('atk'),
      );

      expect(scenarioCustom.evaluate('atk-1'), isTrue);
      expect(scenarioCustom.evaluate('def-1'), isFalse);
    });

    test('EvaluationReport boundary math on empty list', () {
      const emptyReport = EvaluationReport(
        totalScenarios: 0,
        passedScenarios: 0,
        legalMoves: 0,
        failedScenarioIds: [],
      );

      expect(emptyReport.passRate, 0.0);
      expect(emptyReport.legalActionRate, 0.0);
      expect(emptyReport.isSuccessful, isTrue);
    });

    test(
        'HeuristicEnemyPolicy passes 100% of the 20 Track B predefined scenarios',
        () async {
      const runner = EvaluationRunner();
      const policy = HeuristicEnemyPolicy();

      final report = await runner.runSuite(
        scenarios: PredefinedScenarios.all20,
        policy: policy,
      );

      expect(report.totalScenarios, 20);
      expect(report.passedScenarios, 20);
      expect(report.legalMoves, 20);
      expect(report.failedScenarioIds, isEmpty);
      expect(report.passRate, 1.0);
      expect(report.legalActionRate, 1.0);
      expect(report.isSuccessful, isTrue);
    });

    test(
        'SafeFallbackEnemyPolicy intercepts hallucinating policy and passes suite',
        () async {
      const runner = EvaluationRunner();
      final safePolicy = SafeFallbackEnemyPolicy(
        primaryPolicy: _HallucinatingPolicy(),
        fallbackPolicy: const HeuristicEnemyPolicy(),
      );

      final report = await runner.runSuite(
        scenarios: PredefinedScenarios.all20,
        policy: safePolicy,
      );

      expect(report.isSuccessful, isTrue);
      expect(report.legalActionRate, 1.0);
      expect(safePolicy.fallbackActivations, 20);
    });

    test(
        'SafeFallbackEnemyPolicy intercepts timed out policy and activates fallback',
        () async {
      final safePolicy = SafeFallbackEnemyPolicy(
        primaryPolicy: _HangingPolicy(),
        fallbackPolicy: const HeuristicEnemyPolicy(),
        timeout: const Duration(milliseconds: 10),
      );

      final observation = PredefinedScenarios.all20.first.observation;
      final chosen = await safePolicy.chooseAction(observation);

      expect(chosen, 'finisher');
      expect(safePolicy.fallbackActivations, 1);
    });
  });
}
