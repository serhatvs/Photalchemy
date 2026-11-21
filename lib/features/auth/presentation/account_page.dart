import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.notificationsEnabled = false,
    this.onSignIn,
    this.onSignInWithEmail,
    this.onSignOut,
    this.onToggleNotifications,
    this.onSendDemoNotification,
  });

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final bool notificationsEnabled;
  final VoidCallback? onSignIn;
  final void Function(String email, String password)? onSignInWithEmail;
  final VoidCallback? onSignOut;
  final ValueChanged<bool>? onToggleNotifications;
  final VoidCallback? onSendDemoNotification;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _emailController =
      TextEditingController(text: 'alchemist@photalchemy.io');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Photalchemy2026!');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      widget.isAuthenticated
                          ? Icons.person
                          : Icons.person_outline,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isAuthenticated
                        ? 'Alchemist Account'
                        : 'Guest Alchemist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isAuthenticated
                        ? (widget.email ?? 'ID: ${widget.userId}')
                        : 'Sign in to sync your cards and battle across devices.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.isAuthenticated &&
                      widget.userId != null &&
                      widget.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Firebase UID: ${widget.userId}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!widget.isAuthenticated &&
                      widget.onSignInWithEmail != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('auth_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Firebase Email',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('auth_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => widget.onSignInWithEmail!(
                          _emailController.text,
                          _passwordController.text,
                        ),
                        icon: const Icon(Icons.verified_user_outlined),
                        label: const Text('Sign in with Firebase Email'),
                      ),
                    ),
                  ],
                  if (widget.isAuthenticated &&
                      widget.onToggleNotifications != null) ...[
                    const Divider(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dungeon Alerts (FCM)'),
                      subtitle: const Text(
                        'Opt-in to receive exploration & encounter notifications.',
                      ),
                      value: widget.notificationsEnabled,
                      onChanged: widget.onToggleNotifications,
                    ),
                    if (widget.notificationsEnabled &&
                        widget.onSendDemoNotification != null) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonalIcon(
                        onPressed: widget.onSendDemoNotification,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Send Demo FCM Alert'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  if (widget.isAuthenticated)
                    OutlinedButton.icon(
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.onSignIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in with Google'),
                      ),
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
