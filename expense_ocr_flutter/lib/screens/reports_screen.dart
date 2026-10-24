import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';
import 'ai_analysis_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 44,
                ),
                const SizedBox(height: 12),
                const Text('Không thể tải dữ liệu chi tiêu.'),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(expensesProvider);
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (expenses) => _ReportsContent(
          expenses: expenses,
        ),
      ),
    );
  }
}

class _ReportsContent extends StatefulWidget {
  final List<Expense> expenses;

  const _ReportsContent({
    required this.expenses,
  });

  @override
  State<_ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<_ReportsContent> {
  // Biến lưu độ lệch tuần: 0 là tuần này, -1 là tuần trước, v.v.
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Tính ngày Thứ Hai của tuần dựa vào _weekOffset
    final currentMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    final targetMonday = currentMonday.add(Duration(days: _weekOffset * 7));
    final targetSunday = targetMonday.add(const Duration(days: 6));

    final monthlyExpenses = widget.expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();

    final monthlyTotal = monthlyExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tháng ${now.month}/${now.year}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng chi tiêu tháng này'),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(monthlyTotal),
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${monthlyExpenses.length} giao dịch',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Nút Phân tích chi tiêu bằng AI
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.auto_awesome),
            ),
            title: const Text('Phân tích chi tiêu bằng AI'),
            subtitle: const Text(
              'Đánh giá ngân sách và đề xuất mục tiêu tiết kiệm',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AiAnalysisScreen(),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Chi tiêu theo danh mục',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Tỷ lệ được tính trên toàn bộ giao dịch đã lưu.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ExpenseDonutChart(
              expenses: widget.expenses,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Tiêu đề & Nút bấm chuyển tiếp tuần
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiêu theo tuần',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('dd/MM').format(targetMonday)} – ${DateFormat('dd/MM').format(targetSunday)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Tuần trước',
                  onPressed: () {
                    setState(() {
                      _weekOffset--;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Tuần sau',
                  onPressed: _weekOffset < 0
                      ? () {
                          setState(() {
                            _weekOffset++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: WeeklyBarChart(
              expenses: widget.expenses,
              weekOffset: _weekOffset,
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}