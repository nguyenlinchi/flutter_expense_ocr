import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  IconData get categoryIcon {
    switch (expense.category) {
      case 'Ăn uống':
        return Icons.restaurant_rounded;
      case 'Học tập':
        return Icons.menu_book_rounded;
      case 'Di chuyển':
        return Icons.directions_car_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Giải trí':
        return Icons.movie_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color get categoryColor {
    switch (expense.category) {
      case 'Ăn uống':
        return const Color(0xFFE98A38);
      case 'Học tập':
        return const Color(0xFF5276E8);
      case 'Di chuyển':
        return const Color(0xFF17A589);
      case 'Mua sắm':
        return const Color(0xFF9560D9);
      case 'Giải trí':
        return const Color(0xFFE25D7B);
      default:
        return const Color(0xFF718096);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    final dateText = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    ).format(expense.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  categoryIcon,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${expense.category} • $dateText',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-${money.format(expense.amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
