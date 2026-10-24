import '../models/expense.dart';

final List<Expense> demoExpenses = [
  Expense(
    id: 1,
    title: 'Highlands Coffee',
    category: 'Ăn uống',
    amount: 65000,
    date: DateTime.now(),
    note: 'Cà phê và bánh',
  ),
  Expense(
    id: 2,
    title: 'Nhà sách Fahasa',
    category: 'Học tập',
    amount: 120000,
    date: DateTime.now().subtract(const Duration(days: 1)),
    note: 'Mua sách học tập',
  ),
  Expense(
    id: 3,
    title: 'Grab',
    category: 'Di chuyển',
    amount: 35000,
    date: DateTime.now().subtract(const Duration(days: 2)),
    note: 'Di chuyển đến trường',
  ),
  Expense(
    id: 4,
    title: 'Siêu thị',
    category: 'Mua sắm',
    amount: 185000,
    date: DateTime.now().subtract(const Duration(days: 3)),
    note: 'Đồ dùng cá nhân',
  ),
  Expense(
    id: 5,
    title: 'Xem phim',
    category: 'Giải trí',
    amount: 90000,
    date: DateTime.now().subtract(const Duration(days: 5)),
    note: 'Vé xem phim',
  ),
];
