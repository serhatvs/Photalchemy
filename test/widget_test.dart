import 'package:flutter_test/flutter_test.dart';
import 'package:photalchemy/main.dart';

void main() {
  testWidgets('MainApp displays the initial screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('Hello World!'), findsOneWidget);
  });
}
