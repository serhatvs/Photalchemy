import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({
    super.key,
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.notificationsEnabled = false,
    this.onSignIn,
    this.onSignOut,
    this.onToggleNotifications,
    this.onSendDemoNotification,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final bool notificationsEnabled;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onToggleNotifications;
  final VoidCallback? onSendDemoNotification;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
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
                  if (isAuthenticated && onToggleNotifications != null) ...[
                    const Divider(height: 32),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dungeon Alerts (FCM)'),
                      subtitle: const Text(
                        'Opt-in to receive exploration & encounter notifications.',
                      ),
                      value: notificationsEnabled,
                      onChanged: onToggleNotifications,
                    ),
                    if (notificationsEnabled &&
                        onSendDemoNotification != null) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: onSendDemoNotification,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Send Demo FCM Alert'),
                      ),
                    ],
                  ],
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
