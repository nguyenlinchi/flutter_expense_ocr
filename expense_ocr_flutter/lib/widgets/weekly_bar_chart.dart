import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../models/expense.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<Expense> expenses;
  final int weekOffset;

  const WeeklyBarChart({
    super.key,
    required this.expenses,
    this.weekOffset = 0,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.expenses != widget.expenses ||
        oldWidget.weekOffset != widget.weekOffset) {
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
    final now = DateTime.now();

    // DateTime.monday = 1, Sunday = 7.
    final currentMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    // Tính Thứ Hai của tuần dựa trên weekOffset
    final monday = currentMonday.add(Duration(days: widget.weekOffset * 7));

    final dailyTotals = List<double>.filled(7, 0);

    for (final expense in widget.expenses) {
      final date = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      final dayIndex = date.difference(monday).inDays;

      if (dayIndex >= 0 && dayIndex < 7) {
        dailyTotals[dayIndex] += expense.amount;
      }
    }

    final maxAmount = dailyTotals.fold<double>(
      0,
      (currentMax, amount) => math.max(currentMax, amount).toDouble(),
    );

    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 1,
    );

    final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateFormat('dd/MM').format(monday)} – '
          '${DateFormat('dd/MM').format(
            monday.add(const Duration(days: 6)),
          )}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _WeeklyBarPainter(
                  amounts: dailyTotals,
                  labels: labels,
                  maxAmount: maxAmount,
                  progress: Curves.easeOutCubic.transform(
                    _controller.value,
                  ),
                  barColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  gridColor: Theme.of(context).colorScheme.outlineVariant,
                  compactFormat: currencyFormat,
                  textDirection: textDirection,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tổng tuần: ${NumberFormat.currency(
            locale: 'vi_VN',
            symbol: '₫',
            decimalDigits: 0,
          ).format(dailyTotals.fold<double>(
            0,
            (sum, amount) => sum + amount,
          ))}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  final List<double> amounts;
  final List<String> labels;
  final double maxAmount;
  final double progress;
  final Color barColor;
  final Color labelColor;
  final Color gridColor;
  final NumberFormat compactFormat;
  final TextDirection textDirection;

  _WeeklyBarPainter({
    required this.amounts,
    required this.labels,
    required this.maxAmount,
    required this.progress,
    required this.barColor,
    required this.labelColor,
    required this.gridColor,
    required this.compactFormat,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 12.0;
    const rightPadding = 8.0;
    const topPadding = 26.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final slotWidth = chartWidth / 7;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      fontSize: 11,
      color: labelColor,
    );

    // Đường cơ sở.
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      gridPaint,
    );

    for (var i = 0; i < 7; i++) {
      final amount = amounts[i];
      final barHeight = maxAmount > 0
          ? (amount / maxAmount) * chartHeight * progress
          : 0.0;

      final centerX = leftPadding + slotWidth * (i + 0.5);
      final barWidth = math.min(22.0, slotWidth * 0.55).toDouble();

      final barRect = Rect.fromLTWH(
        centerX - barWidth / 2,
        topPadding + chartHeight - barHeight,
        barWidth,
        barHeight,
      );

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          barRect,
          const Radius.circular(6),
        ),
        barPaint,
      );

      // Hiện số tiền phía trên cột khi cột đủ cao.
      if (amount > 0 && barHeight > 22) {
        final amountPainter = TextPainter(
          text: TextSpan(
            text: compactFormat.format(amount),
            style: textStyle.copyWith(fontSize: 9),
          ),
          textDirection: textDirection,
          maxLines: 1,
        );
        amountPainter.layout(maxWidth: slotWidth);

        amountPainter.paint(
          canvas,
          Offset(
            centerX - amountPainter.width / 2,
            topPadding + chartHeight - barHeight - 16,
          ),
        );
      }

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: textStyle,
        ),
        textDirection: textDirection,
      );
      labelPainter.layout();

      labelPainter.paint(
        canvas,
        Offset(
          centerX - labelPainter.width / 2,
          topPadding + chartHeight + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.amounts != amounts ||
        oldDelegate.barColor != barColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textDirection != textDirection;
  }
}