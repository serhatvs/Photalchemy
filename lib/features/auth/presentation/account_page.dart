import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.onSignIn,
    this.onSignOut,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      isAuthenticated ? Icons.person : Icons.person_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAuthenticated ? 'Alchemist Account' : 'Guest Alchemist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAuthenticated
                        ? (email ?? 'ID: $userId')
                        : 'Sign in to sync your cards and battle across devices.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (isAuthenticated)
                    OutlinedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
