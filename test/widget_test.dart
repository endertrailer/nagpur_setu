import 'package:flutter_test/flutter_test.dart';
import 'package:nagpur_setu_flutter/main.dart';

void main() {
  testWidgets('Nagpur Setu app loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const NagpurSetuApp());
    expect(find.text('Nagpur Setu'), findsOneWidget);
  });
}
