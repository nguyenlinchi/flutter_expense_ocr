import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/expense_database.dart';
import '../models/expense.dart';

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  return ExpenseDatabase.instance.getExpenses();
});
