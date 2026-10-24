class ReceiptData {
  final String? merchant;
  final double? amount;
  final DateTime? date;
  final String category;
  final String rawText;

  const ReceiptData({
    this.merchant,
    this.amount,
    this.date,
    this.category = 'Khác',
    required this.rawText,
  });

  ReceiptData copyWith({
    String? merchant,
    double? amount,
    DateTime? date,
    String? category,
  }) {
    return ReceiptData(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      rawText: rawText,
    );
  }
}
