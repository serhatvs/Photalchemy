import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/app/app.dart';
import 'package:photalchemy/features/auth/presentation/account_page.dart';
import 'package:photalchemy/features/battle/domain/enemy_policy.dart';
import 'package:photalchemy/features/battle/presentation/battle_page.dart';
import 'package:photalchemy/features/cards/domain/game_card.dart';
import 'package:photalchemy/features/collection/presentation/collection_page.dart';
import 'package:photalchemy/features/exploration/presentation/explore_page.dart';

void main() {
  testWidgets('AppShell navigates between core screens', (tester) async {
    await tester.pumpWidget(const PhotalchemyApp());

    // Explore tab is initial
    expect(find.text('Capture & Transmute'), findsOneWidget);

    // Navigate to Collection
    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pumpAndSettle();
    expect(find.text('No cards in collection yet'), findsOneWidget);

    // Navigate to Battle
    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Enemy Alchemist'), findsOneWidget);

    // Navigate to Account
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Guest Alchemist'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  group('CollectionPage widget states', () {
    testWidgets('renders loading indicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
            home: Scaffold(body: CollectionPage(isLoading: true))),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your cards...'), findsOneWidget);
    });

    testWidgets('renders error banner and calls retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionPage(
              errorMessage: 'Network timeout loading cards',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Network timeout loading cards'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('renders card grid when cards are provided', (tester) async {
      final sampleCards = [
        GameCard(
          id: 'card-1',
          ownerId: 'player',
          type: CardType.attack,
          rarity: CardRarity.epic,
          stats: const CardStats(strength: 8),
          generationVersion: 'color-v0',
        ),
        GameCard(
          id: 'card-2',
          ownerId: 'player',
          type: CardType.defense,
          rarity: CardRarity.common,
          stats: const CardStats(strength: 3),
          generationVersion: 'color-v0',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CollectionPage(cards: sampleCards)),
        ),
      );

      expect(find.text('ATTACK'), findsOneWidget);
      expect(find.text('DEFENSE'), findsOneWidget);
      expect(find.text('STR 8'), findsOneWidget);
      expect(find.text('STR 3'), findsOneWidget);
    });
  });

  group('BattlePage widget states', () {
    testWidgets('renders HP, shields, turn number and action chips',
        (tester) async {
      LegalEnemyAction? selected;
      final action = LegalEnemyAction(
        id: 'fire-strike',
        cardType: CardType.attack,
        strength: 5,
        effectDescription: 'Deal 5 damage',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattlePage(
              enemyHp: 8,
              maxEnemyHp: 10,
              playerHp: 4,
              maxPlayerHp: 10,
              turnNumber: 3,
              legalActions: [action],
              onActionSelected: (a) => selected = a,
            ),
          ),
        ),
      );

      expect(find.text('Turn 3'), findsOneWidget);
      expect(find.text('HP: 8 / 10  (Shield: 0)'), findsOneWidget);
      expect(find.text('HP: 4 / 10  (Shield: 0)'), findsOneWidget);

      await tester.tap(find.text('fire-strike (5)'));
      expect(selected?.id, 'fire-strike');
    });

    testWidgets('shows resolving turn spinner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BattlePage(isResolvingTurn: true)),
        ),
      );
      expect(find.text('Resolving combat turn...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ExplorePage widget states', () {
    testWidgets('shows permission prompt when permission is denied',
        (tester) async {
      var permissionRequested = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExplorePage(
              hasPermission: false,
              onRequestPermission: () => permissionRequested = true,
            ),
          ),
        ),
      );

      expect(find.text('Camera Access Required'), findsOneWidget);
      await tester.tap(find.text('Grant Camera Permission'));
      expect(permissionRequested, isTrue);
    });

    testWidgets('triggers capture callback', (tester) async {
      var captured = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExplorePage(onCapture: () => captured = true),
          ),
        ),
      );

      await tester.tap(find.text('Capture & Transmute'));
      expect(captured, isTrue);
      await tester.pump();
      expect(
          find.text('Analyzing colors & transmuting card...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
    });
  });

  group('AccountPage widget states', () {
    testWidgets('shows guest mode and sign in button', (tester) async {
      var signedIn = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountPage(
              isAuthenticated: false,
              onSignIn: () => signedIn = true,
            ),
          ),
        ),
      );

      expect(find.text('Guest Alchemist'), findsOneWidget);
      await tester.tap(find.text('Sign in with Google'));
      expect(signedIn, isTrue);
    });

    testWidgets('shows authenticated profile and sign out button',
        (tester) async {
      var signedOut = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountPage(
              isAuthenticated: true,
              email: 'alchemist@photalchemy.io',
              onSignOut: () => signedOut = true,
            ),
          ),
        ),
      );

      expect(find.text('Alchemist Account'), findsOneWidget);
      expect(find.text('alchemist@photalchemy.io'), findsOneWidget);
      await tester.tap(find.text('Sign Out'));
      expect(signedOut, isTrue);
    });
  });
}
