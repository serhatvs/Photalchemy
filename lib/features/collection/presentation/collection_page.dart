import 'package:flutter/material.dart';
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your cards...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Try Again'),
                ),
            ],
          ),
        ),
      );
    }

    final cardList = cards ?? const [];
    if (cardList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.style_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No cards in collection yet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Capture photos in Explore to extract colors and generate unique battle cards.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
