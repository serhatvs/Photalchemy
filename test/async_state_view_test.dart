import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/core/widgets/async_state_view.dart';

void main() {
  group('EmptyStateView', () {
    testWidgets('displays title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'No cards yet',
              message: 'Explore to discover cards.',
            ),
          ),
        ),
      );

      expect(find.text('No cards yet'), findsOneWidget);
      expect(find.text('Explore to discover cards.'), findsOneWidget);
    });

    testWidgets('calls action when button is tapped', (tester) async {
      var actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateView(
              title: 'No cards yet',
              message: 'Explore to discover cards.',
              actionLabel: 'Explore',
              onAction: () {
                actionCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Explore'));
      expect(actionCalled, isTrue);
    });
  });

  group('LoadingStateView', () {
    testWidgets('displays progress indicator and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingStateView(message: 'Loading your collection...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading your collection...'), findsOneWidget);
    });
  });

  group('ErrorStateView', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateView(message: 'Could not load your cards.'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Could not load your cards.'), findsOneWidget);
    });

    testWidgets('calls retry when button is tapped', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateView(
              message: 'Could not load your cards.',
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      expect(retryCalled, isTrue);
    });
  });
}
