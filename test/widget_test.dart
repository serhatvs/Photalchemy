import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/app/app.dart';

void main() {
  testWidgets('PhotalchemyApp displays the initial screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PhotalchemyApp());

    expect(
      find.text('Photo capture and exploration will be connected here.'),
      findsOneWidget,
    );
  });
}
