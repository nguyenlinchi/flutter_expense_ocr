import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/expense_database.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'edit_expense_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';

  static const _categories = [
    'Tất cả',
    'Ăn uống',
    'Di chuyển',
    'Học tập',
    'Mua sắm',
    'Giải trí',
    'Hóa đơn',
    'Sức khỏe',
    'Khác',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editExpense(Expense expense) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(expense: expense),
      ),
    );

    if (updated == true && mounted) {
      ref.invalidate(expensesProvider);
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Xóa giao dịch?'),
          content: Text(
            'Bạn có chắc muốn xóa "${expense.title}" không? '
            'Thao tác này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      if (expense.id == null) {
        throw StateError('Giao dịch không có ID hợp lệ.');
      }

      await ExpenseDatabase.instance.deleteExpense(expense.id!);
      ref.invalidate(expensesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: const Text('Đã xóa giao dịch.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Không thể xóa giao dịch: $error'),
        ),
      );
    }
  }

  /// Gom nhóm giao dịch theo ngày (Chuẩn hóa về yyyy-MM-dd)
  Map<DateTime, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final Map<DateTime, List<Expense>> grouped = {};
    for (var expense in expenses) {
      final dateOnly = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(expense);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Không thể tải giao dịch.'),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(expensesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (expenses) {
          final keyword = _searchController.text.trim().toLowerCase();

          final filteredExpenses = expenses.where((expense) {
            final matchesKeyword =
                expense.title.toLowerCase().contains(keyword) ||
                (expense.note ?? '').toLowerCase().contains(keyword);

            final matchesCategory = _selectedCategory == 'Tất cả' ||
                expense.category == _selectedCategory;

            return matchesKeyword && matchesCategory;
          }).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final totalSum = filteredExpenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          final currencyFormat = NumberFormat.currency(
            locale: 'vi_VN',
            symbol: '₫',
            decimalDigits: 0,
          );

          final groupedExpenses = _groupExpensesByDate(filteredExpenses);

          return SafeArea(
            child: Column(
              children: [
                // Header Tìm kiếm
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm cửa hàng, ghi chú...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHigh,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Thanh chọn Danh mục kiểu Chip bo tròn
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final selected = category == _selectedCategory;

                      return FilterChip(
                        showCheckmark: false,
                        label: Text(category),
                        selected: selected,
                        labelStyle: TextStyle(
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: BorderSide.none,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),

                // Thống kê tổng số lượng & Tổng số tiền
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredExpenses.length} giao dịch',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currencyFormat.format(totalSum),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách phân nhóm theo Ngày
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? _EmptyTransactions(
                          hasFilter: keyword.isNotEmpty ||
                              _selectedCategory != 'Tất cả',
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            ref.invalidate(expensesProvider);
                            await ref.read(expensesProvider.future);
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: groupedExpenses.keys.length,
                            itemBuilder: (context, index) {
                              final date = groupedExpenses.keys.elementAt(index);
                              final dayExpenses = groupedExpenses[date]!;
                              final dayTotal = dayExpenses.fold<double>(
                                0,
                                (sum, item) => sum + item.amount,
                              );

                              return _DayGroupSection(
                                date: date,
                                dayTotal: dayTotal,
                                expenses: dayExpenses,
                                currencyFormat: currencyFormat,
                                onEdit: _editExpense,
                                onDelete: _deleteExpense,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Section nhóm theo từng ngày
class _DayGroupSection extends StatelessWidget {
  final DateTime date;
  final double dayTotal;
  final List<Expense> expenses;
  final NumberFormat currencyFormat;
  final Function(Expense) onEdit;
  final Function(Expense) onDelete;

  const _DayGroupSection({
    required this.date,
    required this.dayTotal,
    required this.expenses,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Hôm nay (${DateFormat('dd/MM').format(date)})';
    } else if (date == yesterday) {
      return 'Hôm qua (${DateFormat('dd/MM').format(date)})';
    } else {
      return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề ngày + Tổng tiền ngày
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatHeaderDate(date),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                currencyFormat.format(dayTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),

        // Các Card giao dịch trong ngày
        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 60,
              endIndent: 16,
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _ModernTransactionItem(
                expense: expense,
                currencyFormat: currencyFormat,
                onEdit: () => onEdit(expense),
                onDelete: () => onDelete(expense),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Item từng giao dịch phong cách hiện đại
class _ModernTransactionItem extends StatelessWidget {
  final Expense expense;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ModernTransactionItem({
    required this.expense,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _colorForCategory(expense.category);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: categoryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _iconForCategory(expense.category),
          color: categoryColor,
          size: 22,
        ),
      ),
      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            expense.category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (expense.note != null && expense.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                expense.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currencyFormat.format(expense.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: theme.colorScheme.outline,
            ),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Sửa'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Di chuyển':
        return Icons.directions_car_rounded;
      case 'Học tập':
        return Icons.menu_book_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Giải trí':
        return Icons.sports_esports_rounded;
      case 'Hóa đơn':
        return Icons.receipt_long_rounded;
      case 'Sức khỏe':
        return Icons.medical_services_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Ăn uống':
        return Colors.orange;
      case 'Di chuyển':
        return Colors.blue;
      case 'Học tập':
        return Colors.purple;
      case 'Mua sắm':
        return Colors.pink;
      case 'Giải trí':
        return Colors.teal;
      case 'Hóa đơn':
        return Colors.redAccent;
      case 'Sức khỏe':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
}

class _EmptyTransactions extends StatelessWidget {
  final bool hasFilter;

  const _EmptyTransactions({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilter ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter
                  ? 'Không tìm thấy giao dịch phù hợp.'
                  : 'Chưa có giao dịch nào được ghi nhận.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}