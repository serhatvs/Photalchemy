import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/app/app.dart';

void main() {
  testWidgets('navigates between initial placeholder screens', (tester) async {
    await tester.pumpWidget(const PhotalchemyApp());

    expect(
      find.text('Photo capture and exploration will be connected here.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Your collection will appear here.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.shield_outlined));
    await tester.pumpAndSettle();
    expect(
      find.text('The turn-based battle system will appear here.'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(
      find.text('Firebase sign-in and account details will appear here.'),
      findsOneWidget,
    );
  });
}
