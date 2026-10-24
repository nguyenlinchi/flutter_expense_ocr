
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _aiEnabled = true;

  double _monthlyBudget = 3000000;
  double _monthlyIncome = 5000000;
  double _savingGoal = 1000000;

  final _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _monthlyBudget = prefs.getDouble('monthly_budget') ?? 3000000;
      _monthlyIncome = prefs.getDouble('monthly_income') ?? 5000000;
      _savingGoal = prefs.getDouble('saving_goal') ?? 1000000;
      _aiEnabled = prefs.getBool('ai_enabled') ?? true;
      _loading = false;
    });
  }

  Future<void> _showFinancialSettingsDialog() async {
    final budgetController = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );
    final incomeController = TextEditingController(
      text: _monthlyIncome.toStringAsFixed(0),
    );
    final savingController = TextEditingController(
      text: _savingGoal.toStringAsFixed(0),
    );

    final formKey = GlobalKey<FormState>();

    double? parseMoney(String value) =>
        double.tryParse(value.trim().replaceAll(',', ''));

    String? validateMoney(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Vui lòng nhập số tiền';
      }

      final amount = parseMoney(value);

      if (amount == null || !amount.isFinite || amount < 0) {
        return 'Nhập số tiền hợp lệ, không âm';
      }

      return null;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ngân sách và mục tiêu'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    validator: validateMoney,
                    decoration: const InputDecoration(
                      labelText: 'Ngân sách tháng',
                      suffixText: 'VNĐ',
                      prefixIcon: Icon(Icons.wallet_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: incomeController,
                    keyboardType: TextInputType.number,
                    validator: validateMoney,
                    decoration: const InputDecoration(
                      labelText: 'Thu nhập dự kiến tháng',
                      suffixText: 'VNĐ',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: savingController,
                    keyboardType: TextInputType.number,
                    validator: validateMoney,
                    decoration: const InputDecoration(
                      labelText: 'Mục tiêu tiết kiệm tháng',
                      suffixText: 'VNĐ',
                      prefixIcon: Icon(Icons.savings_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Đây là mục tiêu do bạn đặt. AI sẽ dùng các giá trị '
                    'này để đưa ra gợi ý, không tự thay đổi chúng.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true && mounted) {
      final budget = parseMoney(budgetController.text)!;
      final income = parseMoney(incomeController.text)!;
      final saving = parseMoney(savingController.text)!;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('monthly_budget', budget);
      await prefs.setDouble('monthly_income', income);
      await prefs.setDouble('saving_goal', saving);

      if (!mounted) return;

      setState(() {
        _monthlyBudget = budget;
        _monthlyIncome = income;
        _savingGoal = saving;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ngân sách và mục tiêu')),
      );
    }

    budgetController.dispose();
    incomeController.dispose();
    savingController.dispose();
  }

  Future<void> _toggleAi(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_enabled', enabled);

    if (!mounted) return;

    setState(() => _aiEnabled = enabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Đã bật phân tích AI'
              : 'Đã tắt phân tích AI',
        ),
      ),
    );
  }

  void _showStorageInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu trữ cục bộ'),
        content: const Text(
          'Giao dịch được lưu trong SQLite trên thiết bị. '
          'Ảnh hóa đơn được lưu trong thư mục ứng dụng. '
          'Khi bạn yêu cầu phân tích AI, ứng dụng chỉ gửi dữ liệu '
          'tổng hợp cần thiết đến backend, không gửi ảnh hóa đơn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quyền riêng tư'),
        content: const Text(
          'Bạn chủ động bấm nút phân tích mới gửi dữ liệu tổng hợp '
          'đến backend. Không gửi API key từ ứng dụng Flutter. '
          'Không gửi tên người dùng, ảnh hóa đơn hoặc ghi chú giao dịch '
          'trong yêu cầu phân tích mặc định.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker AI',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet_outlined,
        size: 40,
      ),
      children: const [
        Text(
          'Ứng dụng quản lý chi tiêu cá nhân với SQLite, OCR '
          'và trợ lý AI hỗ trợ lập kế hoạch tài chính.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 36,
              ),
              SizedBox(height: 12),
              Text(
                'Cài đặt tài chính',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Tùy chỉnh ngân sách và trợ lý AI theo nhu cầu của bạn.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TÀI CHÍNH CÁ NHÂN',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ngân sách và mục tiêu'),
            subtitle: Text(
              'Ngân sách ${_currency.format(_monthlyBudget)} / tháng\n'
              'Tiết kiệm ${_currency.format(_savingGoal)} / tháng',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: _showFinancialSettingsDialog,
          ),
        ),

        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TRỢ LÝ AI',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.smart_toy_outlined),
                title: const Text('Phân tích bằng Gemini'),
                subtitle: Text(
                  _aiEnabled
                      ? 'Đang bật — có thể yêu cầu AI phân tích'
                      : 'Đang tắt — ứng dụng không gọi AI',
                ),
                value: _aiEnabled,
                onChanged: _toggleAi,
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.vpn_key_outlined),
                title: Text('Bảo mật API key'),
                subtitle: Text(
                  'API key được lưu ở backend, không lưu trong Flutter.',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'DỮ LIỆU VÀ ỨNG DỤNG',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('Lưu trữ cục bộ'),
                subtitle: const Text('SQLite và ảnh hóa đơn trên thiết bị'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showStorageInfo,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Quyền riêng tư'),
                subtitle: const Text('Dữ liệu nào được gửi khi dùng AI'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPrivacyInfo,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Thông tin ứng dụng'),
                subtitle: const Text('Expense Tracker AI • Version 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAbout,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Expense Tracker AI',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
