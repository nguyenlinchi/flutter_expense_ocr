import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ocr_flutter/models/receipt_data.dart';
import 'package:expense_ocr_flutter/services/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    test('Đọc số tiền dạng 150.000 VND và ngày Việt Nam', () {
      const text = '''
HIGHLANDS COFFEE
DATE: 17/10/2026
TOTAL: 150.000 VND
''';

      final result = ReceiptParser.parse(text);

      expect(result, isA<ReceiptData>());
      expect(result.amount, 150000);
      expect(result.date, DateTime(2026, 10, 17));
      expect(result.merchant, 'HIGHLANDS COFFEE');
      expect(result.category, 'Ăn uống');
    });

    test('Đọc số tiền dạng 150,000 VND', () {
      const text = '''
FAHASA BOOKSTORE
TOTAL 150,000 VND
''';

      final result = ReceiptParser.parse(text);

      expect(result.amount, 150000);
      expect(result.merchant, 'FAHASA BOOKSTORE');
      expect(result.category, 'Học tập');
    });

    test('Đọc ngày ISO', () {
      const text = '''
CIRCLE K
2026-10-17
TOTAL 25000
''';

      final result = ReceiptParser.parse(text);

      expect(result.date, DateTime(2026, 10, 17));
      expect(result.amount, 25000);
    });

    test('Văn bản rỗng không gây crash', () {
      final result = ReceiptParser.parse('');

      expect(result.amount, isNull);
      expect(result.date, isNull);
      expect(result.merchant, isNull);
    });
  });
}
