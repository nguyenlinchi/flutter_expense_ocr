import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../database/expense_database.dart';
import '../widgets/expense_card.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Hiển thị Form Modal / Dialog để người dùng nhập giao dịch thủ công
  void _showAddExpenseDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    String selectedCategory = 'Ăn uống';
    DateTime selectedDate = DateTime.now();

    final categories = [
      'Ăn uống',
      'Di chuyển',
      'Mua sắm',
      'Giải trí',
      'Hóa đơn',
      'Khác',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm giao dịch thủ công'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề *',
                        hintText: 'Ví dụ: Cơm trưa',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền (VNĐ) *',
                        hintText: 'Ví dụ: 35000',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: const Text('Chọn ngày'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        hintText: 'Ghi chú thêm (không bắt buộc)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final amountText = amountController.text.trim();
                    final amount = double.tryParse(amountText);

                    if (title.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đầy đủ và chính xác tiêu đề & số tiền!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newExpense = Expense(
                      title: title,
                      category: selectedCategory,
                      amount: amount,
                      date: selectedDate,
                      note: noteController.text.trim(),
                    );

                    await ExpenseDatabase.instance.insertExpense(newExpense);
                    ref.invalidate(expensesProvider);

                    if (!context.mounted) return;

                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã thêm giao dịch thành công!'),
                      ),
                    );
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider).value ?? <Expense>[];

    final now = DateTime.now();

    final monthExpenses = expenses.where((e) {
      return e.date.year == now.year && e.date.month == now.month;
    }).toList();

    final total = monthExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF087F6E),
                Color(0xFF13A58A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tổng chi tiêu tháng này',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                money.format(total),
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Chi tiêu được ghi nhận trên thiết bị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút thêm giao dịch thủ công
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => _showAddExpenseDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Thêm giao dịch'),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Tổng quan nhanh',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: const SummaryCard(
                    title: 'Ngân sách tháng',
                    amount: 3000000,
                    icon: Icons.savings_outlined,
                    color: Color(0xFF5276E8),
                    subtitle: 'Mục tiêu đã đặt',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    title: 'Số giao dịch',
                    amount: monthExpenses.length.toDouble(),
                    icon: Icons.receipt_long_outlined,
                    color: const Color(0xFFE98A38),
                    subtitle: 'Trong tháng này',
                    isCurrency: false,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Phân bổ chi tiêu',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('MM/yyyy').format(now),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 155,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: total == 0
                              ? 0
                              : (total / 1000000).clamp(0.0, 1.0),
                          strokeWidth: 18,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          color: Theme.of(context).colorScheme.primary,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Tổng chi',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            money.format(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Đây là biểu đồ minh họa tiến độ chi tiêu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Giao dịch gần đây',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (monthExpenses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Chưa có giao dịch trong tháng này.'),
              ),
            ),
          )
        else
          ...monthExpenses.take(4).map(
                (expense) => ExpenseCard(
                  key: ValueKey(expense.id),
                  expense: expense,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã chọn ${expense.title}'),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}