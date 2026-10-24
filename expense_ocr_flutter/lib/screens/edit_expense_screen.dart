
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/expense_database.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.expense,
  });

  @override
  ConsumerState<EditExpenseScreen> createState() =>
      _EditExpenseScreenState();
}

class _EditExpenseScreenState
    extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late DateTime _selectedDate;
  late String _selectedCategory;

  bool _isSaving = false;

  static const _categories = [
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

    final expense = widget.expense;

    _titleController = TextEditingController(
      text: expense.title,
    );
    _amountController = TextEditingController(
      text: expense.amount.round().toString(),
    );
    _noteController = TextEditingController(
      text: expense.note ?? '',
    );

    _selectedDate = expense.date;
    _selectedCategory = _categories.contains(expense.category)
        ? expense.category
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

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) return;

    setState(() => _isSaving = true);

    try {
      final updatedExpense = widget.expense.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
       note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        clearNote: _noteController.text.trim().isEmpty,
      );

      await ExpenseDatabase.instance.updateExpense(updatedExpense);

      // Làm mới dữ liệu dùng chung cho các màn hình.
      ref.invalidate(expensesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật giao dịch.'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật giao dịch: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: const Text('Sửa giao dịch'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.expense.imagePath != null &&
                  widget.expense.imagePath!.isNotEmpty &&
                  File(widget.expense.imagePath!).existsSync()) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(widget.expense.imagePath!),
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên giao dịch',
                  prefixIcon: Icon(Icons.store_outlined),
                  border: OutlineInputBorder(),
                ),
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
                  helperText: 'Hiện tại: ${currencyFormat.format(
                    double.tryParse(_amountController.text) ?? 0,
                  )}',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').trim(),
                  );

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
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _chooseDate,
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
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
