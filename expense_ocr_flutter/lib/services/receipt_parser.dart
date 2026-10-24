import '../models/receipt_data.dart';

class ReceiptParser {
  ReceiptParser._();

  // Nhận diện ngày: 17/10/2026, 17-10-2026,
  // 2026-10-17 hoặc 2026/10/17.
  static final RegExp _isoDatePattern = RegExp(
    r'\b(20\d{2})[-/](\d{1,2})[-/](\d{1,2})\b',
  );

  static final RegExp _localDatePattern = RegExp(
    r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
  );

  // Số tiền có thể ở dạng 150000, 150.000, 150,000,
  // hoặc 150 000, có thể theo sau bởi VND / VNĐ / đ / ₫.
  static final RegExp _amountPattern = RegExp(
    r'(?<![\d/.-])'
    r'(\d{1,3}(?:[.,\s]\d{3})+|\d{4,})'
    r'\s*(VND|VNĐ|đ|₫)?'
    r'(?!\d)',
    caseSensitive: false,
  );

  static final RegExp _totalKeywordPattern = RegExp(
    r'total|grand\s*total|amount\s*due|'
    r'thanh\s*toan|thanh toan|thanh tien|'
    r'thanh tiền|tong cong|tong tien|'
    r'tổng cộng|tổng tiền|phải trả|'
    r'can tra|cần trả',
    caseSensitive: false,
  );

  static ReceiptData parse(String rawText) {
    final text = rawText.trim();

    if (text.isEmpty) {
      return const ReceiptData(rawText: '');
    }

    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final amount = _extractAmount(lines);
    final date = _extractDate(text);
    final merchant = _extractMerchant(lines);
    final category = _guessCategory(merchant ?? '');

    return ReceiptData(
      merchant: merchant,
      amount: amount,
      date: date,
      category: category,
      rawText: text,
    );
  }

  static double? _extractAmount(List<String> lines) {
    // Ưu tiên dòng chứa từ khóa tổng tiền.
    for (final line in lines.reversed) {
      if (_totalKeywordPattern.hasMatch(line)) {
        final values = _amountsInLine(line);

        if (values.isNotEmpty) {
          return values.last;
        }
      }
    }

    // Nếu không có từ khóa tổng tiền, lấy số tiền lớn nhất
    // trong các dòng có số tiền hợp lệ.
    final candidates = <double>[];

    for (final line in lines) {
      candidates.addAll(_amountsInLine(line));
    }

    if (candidates.isEmpty) return null;

    candidates.sort();
    return candidates.last;
  }

  static List<double> _amountsInLine(String line) {
    final results = <double>[];

    // Bỏ ngày trước khi tìm số tiền để tránh đọc ngày thành tiền.
    final withoutDates = line
        .replaceAll(_isoDatePattern, ' ')
        .replaceAll(_localDatePattern, ' ');

    for (final match in _amountPattern.allMatches(withoutDates)) {
      final rawNumber = match.group(1);

      if (rawNumber == null) continue;

      final digits = rawNumber.replaceAll(
        RegExp(r'[.,\s]'),
        '',
      );

      final value = double.tryParse(digits);

      // Loại các số nhỏ thường không phải tổng chi tiêu.
      if (value != null && value >= 1000) {
        results.add(value);
      }
    }

    return results;
  }

  static DateTime? _extractDate(String text) {
    // Ưu tiên định dạng ISO: yyyy-MM-dd hoặc yyyy/MM/dd.
    final isoMatch = _isoDatePattern.firstMatch(text);

    if (isoMatch != null) {
      final year = int.parse(isoMatch.group(1)!);
      final month = int.parse(isoMatch.group(2)!);
      final day = int.parse(isoMatch.group(3)!);

      return _makeValidDate(year, month, day);
    }

    // Định dạng Việt Nam: dd/MM/yyyy hoặc dd-MM-yyyy.
    final localMatch = _localDatePattern.firstMatch(text);

    if (localMatch != null) {
      final day = int.parse(localMatch.group(1)!);
      final month = int.parse(localMatch.group(2)!);
      var year = int.parse(localMatch.group(3)!);

      if (year < 100) {
        year += year <= 69 ? 2000 : 1900;
      }

      return _makeValidDate(year, month, day);
    }

    return null;
  }

  static DateTime? _makeValidDate(
    int year,
    int month,
    int day,
  ) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);

    // DateTime tự chuyển ngày không hợp lệ sang tháng sau;
    // kiểm tra lại để tránh nhận nhầm 31/02.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  static String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final normalized = line.toLowerCase();

      if (line.length < 3) continue;

      if (_totalKeywordPattern.hasMatch(line)) continue;

      if (_isoDatePattern.hasMatch(line) || _localDatePattern.hasMatch(line)) {
        continue;
      }

      if (RegExp(
        r'^(invoice|receipt|bill|hoa don|hóa đơn|'
        r'cashier|thu ngan|nhân viên|ma so|mã số|'
        r'address|dia chi|địa chỉ)\b',
        caseSensitive: false,
      ).hasMatch(normalized)) {
        continue;
      }

      // Bỏ các dòng chỉ chứa số và ký tự phân cách.
      if (RegExp(r'^[\d\s.,:/-]+$').hasMatch(line)) {
        continue;
      }

      return line;
    }

    return null;
  }

  static String _guessCategory(String merchant) {
    final value = merchant.toLowerCase();

    if (RegExp(
      r'coffee|cafe|cà phê|highlands|starbucks|'
      r'restaurant|nhà hàng|food|bánh|phở|bún|'
      r'lotteria|kfc|mcdonald',
    ).hasMatch(value)) {
      return 'Ăn uống';
    }

    if (RegExp(
      r'grab|be\b|taxi|bus|xe buýt|xăng|'
      r'parking|gửi xe|vận tải',
    ).hasMatch(value)) {
      return 'Di chuyển';
    }

    if (RegExp(
      r'fahasa|nhà sách|book|school|university|'
      r'học phí|education',
    ).hasMatch(value)) {
      return 'Học tập';
    }

    if (RegExp(
      r'supermarket|siêu thị|circle k|winmart|'
      r'coopmart|bách hóa|shopping|mall',
    ).hasMatch(value)) {
      return 'Mua sắm';
    }

    if (RegExp(
      r'cinema|rạp phim|movie|game|entertainment',
    ).hasMatch(value)) {
      return 'Giải trí';
    }

    return 'Khác';
  }
}
