import 'package:flutter/material.dart';
import 'package:photalchemy/core/widgets/feature_placeholder.dart';

class BattlePage extends StatelessWidget {
  const BattlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.shield_outlined,
      title: 'Dungeon battles',
      message: 'The turn-based battle system will appear here.',
    );
  }
}
