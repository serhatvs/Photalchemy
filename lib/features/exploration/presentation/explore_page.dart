import 'package:flutter/material.dart';
import 'package:photalchemy/core/widgets/feature_placeholder.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.camera_alt_outlined,
      title: 'Explore the world',
      message: 'Photo capture and exploration will be connected here.',
    );
  }
}
