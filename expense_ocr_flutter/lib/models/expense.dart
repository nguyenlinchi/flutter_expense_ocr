class Expense {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String? imagePath;
  final String? note;

  const Expense({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.imagePath,
    this.note,
  });

  /// Chuyển Expense thành Map để lưu vào SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'image_path': imagePath,
      'note': note,
    };
  }

  /// Chuyển một bản ghi SQLite thành Expense.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      imagePath: map['image_path'] as String?,
      note: map['note'] as String?,
    );
  }

  /// Tạo bản sao khi cần cập nhật một số trường.
 
Expense copyWith({
  int? id,
  String? title,
  String? category,
  double? amount,
  DateTime? date,
  String? imagePath,
  String? note,
  bool clearNote = false,
}) {
  return Expense(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    imagePath: imagePath ?? this.imagePath,
    note: clearNote ? null : (note ?? this.note),
  );
}

}
