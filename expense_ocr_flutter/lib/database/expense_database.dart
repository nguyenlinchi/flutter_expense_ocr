import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class ExpenseDatabase {
  ExpenseDatabase._internal();

  static final ExpenseDatabase instance = ExpenseDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'expenses.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            image_path TEXT,
            note TEXT
          )
        ''');
      },
    );
  }

  // CREATE: thêm giao dịch.
  Future<int> insertExpense(Expense expense) async {
    final db = await database;

    final data = expense.toMap()..remove('id');

    return db.insert(
      'expenses',
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // READ: lấy toàn bộ giao dịch, mới nhất trước.
  Future<List<Expense>> getExpenses({
    String? category,
    String? keyword,
  }) async {
    final db = await database;

    final conditions = <String>[];
    final arguments = <Object?>[];

    if (category != null && category.isNotEmpty && category != 'Tất cả') {
      conditions.add('category = ?');
      arguments.add(category);
    }

    if (keyword != null && keyword.trim().isNotEmpty) {
      conditions.add('title LIKE ?');
      arguments.add('%${keyword.trim()}%');
    }

    final rows = await db.query(
      'expenses',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: arguments.isEmpty ? null : arguments,
      orderBy: 'date DESC, id DESC',
    );

    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  // UPDATE: cập nhật giao dịch.
  Future<int> updateExpense(Expense expense) async {
    final db = await database;

    if (expense.id == null) {
      throw ArgumentError(
        'Không thể cập nhật giao dịch chưa có ID.',
      );
    }

    final data = expense.toMap()..remove('id');

    return db.update(
      'expenses',
      data,
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // DELETE: xóa giao dịch.
  Future<int> deleteExpense(int id) async {
    final db = await database;

    return db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Tổng chi tiêu trong tháng.
  Future<double> getMonthlyTotal(DateTime month) async {
    final db = await database;

    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE date >= ? AND date < ?
      ''',
      [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
    );

    return (result.first['total'] as num).toDouble();
  }

  Future<void> close() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
