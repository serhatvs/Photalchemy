import 'package:flutter/material.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

class BattlePage extends StatelessWidget {
  const BattlePage({
    super.key,
    this.enemyHp = 10,
    this.maxEnemyHp = 10,
    this.enemyShield = 0,
    this.playerHp = 10,
    this.maxPlayerHp = 10,
    this.playerShield = 0,
    this.turnNumber = 1,
    this.isResolvingTurn = false,
    this.legalActions = const [],
    this.onActionSelected,
  });

  final int enemyHp;
  final int maxEnemyHp;
  final int enemyShield;
  final int playerHp;
  final int maxPlayerHp;
  final int playerShield;
  final int turnNumber;
  final bool isResolvingTurn;
  final List<LegalEnemyAction> legalActions;
  final ValueChanged<LegalEnemyAction>? onActionSelected;

  @override
  Widget build(BuildContext context) {
    final enemyRatio =
        maxEnemyHp > 0 ? (enemyHp / maxEnemyHp).clamp(0.0, 1.0) : 0.0;
    final playerRatio =
        maxPlayerHp > 0 ? (playerHp / maxPlayerHp).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Enemy Combat Card
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.smart_toy_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Enemy Alchemist',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text('Turn $turnNumber'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: enemyRatio,
                    color: Colors.red,
                    backgroundColor: Colors.red.shade100,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HP: $enemyHp / $maxEnemyHp  (Shield: $enemyShield)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Turn resolution feedback or VS banner
          Center(
            child: isResolvingTurn
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Resolving combat turn...'),
                    ],
                  )
                : Text(
                    'VS',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
          ),

          const Spacer(),

          // Player Combat Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Player',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: playerRatio,
                    color: Colors.green,
                    backgroundColor: Colors.green.shade100,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HP: $playerHp / $maxPlayerHp  (Shield: $playerShield)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons / Hand
          if (legalActions.isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.tonalIcon(
                  onPressed: isResolvingTurn ? null : () {},
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Attack (4)'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isResolvingTurn ? null : () {},
                  icon: const Icon(Icons.shield),
                  label: const Text('Defend (3)'),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: legalActions.map((action) {
                return ActionChip(
                  avatar: Icon(
                    action.cardType == CardType.attack
                        ? Icons.flash_on
                        : Icons.shield,
                    size: 16,
                  ),
                  label: Text('${action.id} (${action.strength})'),
                  onPressed: isResolvingTurn
                      ? null
                      : () => onActionSelected?.call(action),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
