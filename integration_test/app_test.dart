import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voicescribe_mobile/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('verify app starts and shows recording screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that the app shell shows the Recording tab initially
      expect(find.text('Recording'), findsWidgets);
    });
  });
}
