import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';
import '../../../core/theme/app_theme.dart';

final budgetStreamProvider = StreamProvider<BudgetModel?>((ref) {
  return ref.watch(budgetRepositoryProvider).getBudget();
});

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final limit = double.tryParse(_limitController.text);
    if (limit == null) return;

    try {
      await ref.read(budgetRepositoryProvider).setBudget(BudgetModel(limit: limit));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.budgetUpdated)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetAsync = ref.watch(budgetStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budget)),
      body: budgetAsync.when(
        data: (budget) {
          if (budget != null && _limitController.text.isEmpty) {
            _limitController.text = budget.limit.toString();
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.monthly,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    suffixText: '€',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l10n.save),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
