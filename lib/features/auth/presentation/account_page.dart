import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    this.isAuthenticated = false,
    this.isAuthBusy = false,
    this.authErrorMessage,
    this.userId,
    this.email,
    this.notificationsEnabled = false,
    this.onSignIn,
    this.onSignInWithEmail,
    this.onRegisterWithEmail,
    this.onSignOut,
    this.onToggleNotifications,
    this.onSendDemoNotification,
  });

  final bool isAuthenticated;
  final bool isAuthBusy;
  final String? authErrorMessage;
  final String? userId;
  final String? email;
  final bool notificationsEnabled;
  final VoidCallback? onSignIn;
  final void Function(String email, String password)? onSignInWithEmail;
  final void Function(String email, String password)? onRegisterWithEmail;
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
                    radius: 26,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      widget.isAuthenticated
                          ? Icons.person
                          : Icons.person_outline,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isAuthenticated
                        ? 'Alchemist Account'
                        : 'Guest Alchemist',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isAuthenticated
                        ? (widget.email ?? 'ID: ${widget.userId}')
                        : 'Sign in or create a Firebase account to sync your cards.',
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
                  if (widget.authErrorMessage != null &&
                      !widget.isAuthenticated) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.authErrorMessage!,
                        key: const Key('auth_error_banner'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (!widget.isAuthenticated &&
                      widget.onSignInWithEmail != null) ...[
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('auth_email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Firebase Email',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          tooltip: 'Clear email',
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _emailController.clear,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('auth_password_field'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Password (min 6 chars)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          tooltip: 'Clear password',
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _passwordController.clear,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: widget.isAuthBusy
                                ? null
                                : () => widget.onSignInWithEmail!(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                            icon: const Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                            ),
                            label: const Text('Sign In (Email)'),
                          ),
                        ),
                        if (widget.onRegisterWithEmail != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.isAuthBusy
                                  ? null
                                  : () => widget.onRegisterWithEmail!(
                                        _emailController.text,
                                        _passwordController.text,
                                      ),
                              icon: const Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 18,
                              ),
                              label: const Text('Create Account'),
                            ),
                          ),
                        ],
                      ],
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
                  const SizedBox(height: 10),
                  if (widget.isAuthenticated)
                    OutlinedButton.icon(
                      onPressed: widget.isAuthBusy ? null : widget.onSignOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.isAuthBusy ? null : widget.onSignIn,
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
