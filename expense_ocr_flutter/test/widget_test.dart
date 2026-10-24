import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr_flutter/main.dart';

void main() {
  testWidgets('ExpenseTrackerApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseTrackerApp());

    // Verify that our app starts and displays the title or key elements.
    expect(find.text('Tổng quan'), findsOneWidget);
  });
}
