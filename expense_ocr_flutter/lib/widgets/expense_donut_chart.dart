
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseDonutChart extends StatefulWidget {
  final List<Expense> expenses;

  const ExpenseDonutChart({
    super.key,
    required this.expenses,
  });

  @override
  State<ExpenseDonutChart> createState() =>
      _ExpenseDonutChartState();
}

class _ExpenseDonutChartState extends State<ExpenseDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Map<String, Color> _categoryColors = {
    'Ăn uống': Color(0xFF6C63FF),
    'Di chuyển': Color(0xFF00BFA6),
    'Học tập': Color(0xFFFFB547),
    'Mua sắm': Color(0xFFFF6584),
    'Giải trí': Color(0xFF42A5F5),
    'Hóa đơn': Color(0xFFAB47BC),
    'Sức khỏe': Color(0xFF66BB6A),
    'Khác': Color(0xFF90A4AE),
  };

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ExpenseDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.expenses != widget.expenses) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};

    for (final expense in widget.expenses) {
      totals.update(
        expense.category,
        (current) => current + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalAmount = widget.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    if (widget.expenses.isEmpty || totalAmount <= 0) {
      return const _EmptyChart(
        message: 'Chưa có dữ liệu chi tiêu',
      );
    }

    final sections = sortedEntries.map((entry) {
      return _DonutSection(
        category: entry.key,
        amount: entry.value,
        color: _categoryColors[entry.key] ??
            const Color(0xFF78909C),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _DonutPainter(
                  sections: sections,
                  total: totalAmount,
                  progress: Curves.easeOutCubic.transform(
                    _controller.value,
                  ),
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tổng chi tiêu',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currencyFormat.format(totalAmount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ...sortedEntries.map((entry) {
          final color = _categoryColors[entry.key] ??
              const Color(0xFF78909C);
          final percentage = entry.value / totalAmount * 100;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currencyFormat.format(entry.value),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DonutSection {
  final String category;
  final double amount;
  final Color color;

  const _DonutSection({
    required this.category,
    required this.amount,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSection> sections;
  final double total;
  final double progress;
  final Color backgroundColor;

  _DonutPainter({
    required this.sections,
    required this.total,
    required this.progress,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
    (math.min(size.width, size.height) * 0.38).toDouble();
    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    const strokeWidth = 25.0;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    if (total <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var startAngle = -math.pi / 2;
    final visibleSweep = 2 * math.pi * progress;

    for (final section in sections) {
      final sweepAngle =
          2 * math.pi * section.amount / total;

      if (visibleSweep <= 0) break;

      final remaining = visibleSweep -
          (startAngle + math.pi / 2);

      if (remaining <= 0) break;

      paint.color = section.color;

      canvas.drawArc(
        rect,
        startAngle,
        math.min(sweepAngle, remaining).toDouble(),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.sections != sections ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message),
          ],
        ),
      ),
    );
  }
}
