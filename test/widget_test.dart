import 'package:flutter_test/flutter_test.dart';

import 'package:insighted/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const InsightEdApp());
    await tester.pump();
    expect(find.text('Welcome to'), findsOneWidget);
  });
}
