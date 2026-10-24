
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../database/expense_database.dart';
import '../models/ai_analysis.dart';

class AiAnalysisService {
  AiAnalysisService._();

  // Android Emulator: 10.0.2.2 trỏ về máy tính đang chạy backend.
  // Có thể thay URL khi chạy điện thoại thật hoặc backend đã deploy.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static Future<AiAnalysis> analyzeCurrentMonth() async {
    final prefs = await SharedPreferences.getInstance();

    if (!(prefs.getBool('ai_enabled') ?? true)) {
      throw Exception(
        'Bạn đã tắt phân tích AI trong phần Cài đặt.',
      );
    }

    final now = DateTime.now();

    final expenses = await ExpenseDatabase.instance.getExpenses();

    final monthlyExpenses = expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month;
    }).toList();

    double totalSpent = 0;
    final Map<String, double> categoryTotals = {};

    for (final expense in monthlyExpenses) {
      totalSpent += expense.amount;

      categoryTotals.update(
        expense.category,
        (current) => current + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final budget = prefs.getDouble('monthly_budget') ?? 0;
    final income = prefs.getDouble('monthly_income') ?? 0;
    final savingGoal = prefs.getDouble('saving_goal') ?? 0;

    // Không gửi từng giao dịch, tên cửa hàng, ghi chú hoặc ảnh hóa đơn.
    final payload = <String, dynamic>{
      'month':
          '${now.year}-${now.month.toString().padLeft(2, '0')}',
      'monthlyIncome': income,
      'monthlyBudget': budget,
      'savingGoal': savingGoal,
      'totalSpent': totalSpent,
      'transactionCount': monthlyExpenses.length,
      'categoryTotals': categoryTotals,
    };

    final uri = Uri.parse('$_baseUrl/api/analyze');

    final response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 55));

    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Backend không trả về JSON hợp lệ '
        '(HTTP ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(
        body['error']?.toString() ??
            'Không thể phân tích chi tiêu '
                '(HTTP ${response.statusCode}).',
      );
    }

    final rawAnalysis = body['analysis'];

    if (rawAnalysis is! Map) {
      throw Exception('Backend chưa trả về kết quả phân tích.');
    }

    return AiAnalysis.fromJson(
      Map<String, dynamic>.from(rawAnalysis),
    );
  }
}
