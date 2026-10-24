
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ai_analysis.dart';
import '../services/ai_analysis_service.dart';

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen> {
  AiAnalysis? _result;
  bool _loading = false;
  String? _error;

  final _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  Future<void> _runAnalysis() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AiAnalysisService.analyzeCurrentMonth();

      if (!mounted) return;

      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'good':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'good':
        return 'Chi tiêu trong tầm kiểm soát';
      case 'warning':
        return 'Cần chú ý ngân sách';
      case 'high':
        return 'Chi tiêu ở mức cao';
      default:
        return 'Chưa đủ dữ liệu đánh giá';
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard(Widget child) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích chi tiêu AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
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
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(height: 12),
                Text(
                  'Trợ lý tài chính cá nhân',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 21,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Phân tích giao dịch tháng này và tìm cách '
                  'quản lý ngân sách hiệu quả hơn.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _loading ? null : _runAnalysis,
              icon: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _loading
                    ? 'Đang phân tích...'
                    : result == null
                        ? 'Phân tích chi tiêu của tôi'
                        : 'Phân tích lại',
              ),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Đang tổng hợp dữ liệu và chờ AI phản hồi...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            _contentCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Không thể phân tích',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_error!),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loading ? null : _runAnalysis,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ],

          if (result != null) ...[
            _sectionTitle(
              'Đánh giá tổng quan',
              Icons.assessment_outlined,
            ),
            _contentCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: _statusColor(result.status),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusText(result.status),
                          style: TextStyle(
                            color: _statusColor(result.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(result.summary),
                ],
              ),
            ),

            _sectionTitle(
              'Những điều cần chú ý',
              Icons.lightbulb_outline,
            ),
            _contentCard(
              result.insights.isEmpty
                  ? const Text('Chưa có nhận xét chi tiết.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final insight in result.insights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(insight)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            _sectionTitle(
              'Mục tiêu chi tiêu theo tuần',
              Icons.calendar_month_outlined,
            ),
            _contentCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _money.format(result.recommendedWeeklyLimit),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hạn mức tham khảo cho một tuần',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(result.weeklyReason),
                ],
              ),
            ),

            _sectionTitle(
              'Đề xuất hành động',
              Icons.flag_outlined,
            ),
            if (result.recommendations.isEmpty)
              _contentCard(
                const Text('Chưa có đề xuất cụ thể.'),
              )
            else
              for (final recommendation in result.recommendations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _contentCard(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(recommendation.detail),
                        const SizedBox(height: 12),
                        Text(
                          'Hạn mức gợi ý: '
                          '${_money.format(recommendation.weeklyLimit)} / tuần',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            const SizedBox(height: 12),
            Text(
              result.disclaimer,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
