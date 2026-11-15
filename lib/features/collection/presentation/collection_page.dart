import 'package:flutter/material.dart';
import 'package:photalchemy/core/widgets/async_state_view.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    super.key,
    this.cards,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<GameCard>? cards;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingStateView(message: 'Loading your cards...');
    }

    if (errorMessage != null) {
      return ErrorStateView(
        message: errorMessage!,
        onRetry: onRetry,
        retryLabel: 'Try Again',
      );
    }

    final cardList = cards ?? const [];
    if (cardList.isEmpty) {
      return const EmptyStateView(
        icon: Icons.style_outlined,
        title: 'No cards in collection yet',
        message:
            'Capture photos in Explore to extract colors and generate unique battle cards.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cardList.length,
      itemBuilder: (context, index) {
        final card = cardList[index];
        return _GameCardTile(card: card);
      },
    );
  }
}

class _GameCardTile extends StatelessWidget {
  const _GameCardTile({required this.card});

  final GameCard card;

  Color _typeColor(CardType type) {
    switch (type) {
      case CardType.attack:
        return Colors.red.shade700;
      case CardType.defense:
        return Colors.blue.shade700;
      case CardType.stun:
        return Colors.amber.shade800;
      case CardType.reflect:
        return Colors.purple.shade700;
    }
  }

  IconData _typeIcon(CardType type) {
    switch (type) {
      case CardType.attack:
        return Icons.flash_on;
      case CardType.defense:
        return Icons.shield;
      case CardType.stun:
        return Icons.bolt;
      case CardType.reflect:
        return Icons.cached;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(card.type);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: color.withAlpha(35),
            child: Row(
              children: [
                Icon(_typeIcon(card.type), size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    card.type.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  card.rarity.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                _typeIcon(card.type),
                size: 48,
                color: color.withAlpha(120),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.id,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'STR ${card.stats.strength}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
