import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import '../../features/budget/presentation/budget_screen.dart';
import '../../features/transactions/providers/transaction_provider.dart';
import '../../core/theme/app_theme.dart';

class BudgetProgressBar extends ConsumerWidget {
  const BudgetProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgetAsync = ref.watch(budgetStreamProvider);
    final monthlyExpense = ref.watch(currentMonthExpenseProvider);

    return budgetAsync.when(
      data: (budget) {
        if (budget == null || budget.limit <= 0) return const SizedBox.shrink();

        final percent = (monthlyExpense / budget.limit).clamp(0.0, 1.0);
        final isExceeded = monthlyExpense > budget.limit;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isExceeded ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.budget, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${monthlyExpense.toStringAsFixed(2)} / ${budget.limit.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExceeded ? Colors.red : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: Colors.grey[200],
                  color: isExceeded ? Colors.red : AppColors.primary,
                ),
              ),
              if (isExceeded) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.budgetExceeded,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
