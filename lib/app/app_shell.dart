import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photalchemy/app/app_controller.dart';
import 'package:photalchemy/core/notifications/notification_service.dart';
import 'package:photalchemy/features/auth/domain/auth_repository.dart';
import 'package:photalchemy/features/auth/domain/profile_repository.dart';
import 'package:photalchemy/features/auth/presentation/account_page.dart';
import 'package:photalchemy/features/battle/presentation/battle_page.dart';
import 'package:photalchemy/features/cards/domain/card_repository.dart';
import 'package:photalchemy/features/collection/presentation/collection_page.dart';
import 'package:photalchemy/features/exploration/presentation/explore_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.controller,
    this.authRepository,
    this.cardRepository,
    this.profileRepository,
    this.notificationService,
  });

  final AppController? controller;
  final AuthRepository? authRepository;
  final CardRepository? cardRepository;
  final ProfileRepository? profileRepository;
  final NotificationService? notificationService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final AppController _controller;
  late final bool _ownsController;
  StreamSubscription<String>? _messageSub;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        AppController(
          authRepository: widget.authRepository,
          cardRepository: widget.cardRepository,
          profileRepository: widget.profileRepository,
          notificationService: widget.notificationService,
        );

    _messageSub = _controller.messages.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final battle = _controller.battleState;
        return Scaffold(
          appBar: AppBar(title: const Text('Photalchemy')),
          body: SafeArea(
            child: IndexedStack(
              index: _controller.selectedIndex,
              children: [
                ExplorePage(
                  hasPermission: _controller.hasCameraPermission,
                  onRequestPermission: _controller.grantCameraPermission,
                  onCapture: _controller.captureAndTransmute,
                  locationPermission: _controller.locationPermission,
                  currentCellName: _controller.currentCellName,
                  currentCellKey: _controller.currentLocation?.cellKey,
                  currentCellCaptures: _controller.currentCellCaptures,
                  repeatDecayThreshold: _controller.repeatDecayThreshold,
                  availableCells: _controller.availableCells,
                  onSelectCell: _controller.selectExplorationCell,
                  onToggleLocationOptOut: _controller.toggleLocationOptOut,
                ),
                CollectionPage(
                  cards: _controller.collection,
                  isLoading: _controller.isCollectionLoading,
                  errorMessage: _controller.collectionErrorMessage,
                  onRetry: _controller.reloadCollection,
                ),
                BattlePage(
                  enemyHp: battle.enemy.hp,
                  maxEnemyHp: battle.enemy.maxHp,
                  enemyShield: battle.enemy.shield,
                  isEnemyStunned: battle.enemy.isStunned,
                  playerHp: battle.player.hp,
                  maxPlayerHp: battle.player.maxHp,
                  playerShield: battle.player.shield,
                  isPlayerStunned: battle.player.isStunned,
                  turnNumber: battle.turnNumber,
                  isResolvingTurn: _controller.isResolvingTurn,
                  isGameOver: battle.isGameOver,
                  winner: battle.winner,
                  lastTurnSummary: _controller.lastTurnSummary,
                  legalActions: _controller.playerActions,
                  onActionSelected: _controller.playBattleTurn,
                  onResetBattle: _controller.resetBattle,
                ),
                AccountPage(
                  isAuthenticated: _controller.isAuthenticated,
                  isAuthBusy: _controller.isAuthBusy,
                  authErrorMessage: _controller.authErrorMessage,
                  userId: _controller.userId,
                  email: _controller.userEmail,
                  notificationsEnabled: _controller.notificationsEnabled,
                  onSignIn: _controller.signInWithGoogle,
                  onSignInWithEmail: (email, password) =>
                      _controller.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  ),
                  onRegisterWithEmail: (email, password) =>
                      _controller.registerWithEmailAndPassword(
                    email: email,
                    password: password,
                  ),
                  onSignOut: _controller.signOut,
                  onToggleNotifications: _controller.toggleNotifications,
                  onSendDemoNotification: _controller.sendDemoNotification,
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _controller.selectedIndex,
            onDestinationSelected: _controller.selectTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.style_outlined),
                selectedIcon: Icon(Icons.style),
                label: 'Cards',
              ),
              NavigationDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield),
                label: 'Battle',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Account',
              ),
            ],
          ),
        );
      },
    );
  }
}
