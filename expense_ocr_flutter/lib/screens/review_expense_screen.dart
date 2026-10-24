

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/expense_database.dart';
import '../models/expense.dart';
import '../models/receipt_data.dart';
import '../providers/expense_provider.dart';

class ReviewExpenseScreen extends ConsumerStatefulWidget {
  final ReceiptData receiptData;
  final String imagePath;

  const ReviewExpenseScreen({
    super.key,
    required this.receiptData,
    required this.imagePath,
  });

  @override
  ConsumerState<ReviewExpenseScreen> createState() =>
      _ReviewExpenseScreenState();
}

class _ReviewExpenseScreenState
    extends ConsumerState<ReviewExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  late String _selectedCategory;

  bool _isSaving = false;

  static const List<String> _categories = [
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
  void initState() {
    super.initState();

    final receipt = widget.receiptData;

    _titleController = TextEditingController(
      text: receipt.merchant ?? '',
    );

    _amountController = TextEditingController(
      text: receipt.amount == null
          ? ''
          : receipt.amount!.round().toString(),
    );

    _noteController = TextEditingController();

    _selectedDate = receipt.date ?? DateTime.now();

    _selectedCategory = _categories.contains(receipt.category)
        ? receipt.category
        : 'Khác';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      helpText: 'Chọn ngày giao dịch',
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountDigits = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final amount = double.tryParse(amountDigits);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final expense = Expense(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
        imagePath: widget.imagePath,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await ExpenseDatabase.instance.insertExpense(expense);

      // Làm mới danh sách giao dịch từ SQLite.
      ref.invalidate(expensesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu giao dịch thành công!'),
        ),
      );

      // Báo cho màn hình trước biết đã lưu thành công.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu giao dịch: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận giao dịch'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: Theme.of(context)
                          .colorScheme.surfaceContainerHighest,
                      child: const Text(
                        'Không thể hiển thị ảnh hóa đơn',
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Kiểm tra thông tin',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Thông tin được nhận diện tự động. '
                'Hãy kiểm tra và chỉnh sửa trước khi lưu.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tên cửa hàng / giao dịch',
                  prefixIcon: Icon(Icons.store_outlined),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên giao dịch.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Số tiền (VND)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: '₫',
                  border: const OutlineInputBorder(),
                  helperText: _amountController.text.isEmpty
                      ? 'Nhập số tiền bằng VND, không cần dấu chấm.'
                      : 'Giá trị hiện tại: ${currencyFormat.format(
                          double.tryParse(_amountController.text) ?? 0,
                        )}',
                ),
                onChanged: (_) {
                  setState(() {});
                },
                validator: (value) {
                  final digits = (value ?? '').trim();

                  if (digits.isEmpty) {
                    return 'Vui lòng nhập số tiền.';
                  }

                  final amount = double.tryParse(digits);

                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _chooseDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày giao dịch',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isSaving ? null : _saveExpense,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Xác nhận và lưu',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
