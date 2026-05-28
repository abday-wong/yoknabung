import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yoknabung/main.dart';
import 'package:yoknabung/providers/savings_provider.dart';

void main() {
  testWidgets('Smoke test - App title display', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SavingsProvider(),
        child: const YokNabungApp(),
      ),
    );

    // Verify that our app name is present in the AppBar.
    expect(find.text('YOKNABUNG'), findsOneWidget);
  });
}
