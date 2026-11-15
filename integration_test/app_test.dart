import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photalchemy/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'P1 end-to-end journey: explore capture -> cards -> battle -> account & FCM',
    (tester) async {
      await tester.pumpWidget(const PhotalchemyApp());
      await tester.pumpAndSettle();

      // 1. Explore tab: capture and transmute a card
      expect(find.text('Capture & Transmute'), findsOneWidget);
      await tester.tap(find.text('Capture & Transmute'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      // Allow SnackBar to dismiss before switching tabs
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 2. Cards tab: verify starter card and synthesized card are listed
      await tester.tap(find.byIcon(Icons.style_outlined));
      await tester.pumpAndSettle();
      expect(find.text('starter-ember'), findsOneWidget);
      expect(find.text('card-2'), findsOneWidget);

      // 3. Battle tab: resolve a simultaneous turn
      await tester.tap(find.byIcon(Icons.shield_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Turn 1'), findsOneWidget);
      await tester.tap(find.text('slash (4)'));
      await tester.pumpAndSettle();
      expect(find.text('Turn 2'), findsOneWidget);

      // 4. Account tab: sign in, opt into FCM alerts, send demo alert, sign out
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Alchemist Account'), findsOneWidget);

      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final demoAlertButton = find.text('Send Demo FCM Alert');
      await tester.ensureVisible(demoAlertButton);
      await tester.tap(demoAlertButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('FCM [dungeon_alerts]:'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign Out'));
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(find.text('Guest Alchemist'), findsOneWidget);
    },
  );
}
