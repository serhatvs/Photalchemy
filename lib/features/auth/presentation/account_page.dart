import 'package:flutter/material.dart';
import 'package:photalchemy/core/widgets/feature_placeholder.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      icon: Icons.person_outline,
      title: 'Player account',
      message: 'Firebase sign-in and account details will appear here.',
    );
  }
}
