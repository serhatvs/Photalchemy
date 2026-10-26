import 'package:flutter/material.dart';
import 'package:photalchemy/core/widgets/feature_placeholder.dart';

class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.style_outlined,
      title: 'Your cards',
      message: 'Your collection will appear here.',
    );
  }
}
