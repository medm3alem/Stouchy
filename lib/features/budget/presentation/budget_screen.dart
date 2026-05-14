import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../currency/providers/currency_provider.dart';

final budgetStreamProvider = StreamProvider<BudgetModel?>((ref) {
  return ref.watch(budgetRepositoryProvider).getBudget();
});

final convertedBudgetProvider = Provider<AsyncValue<BudgetModel?>>((ref) {
  final budgetAsync = ref.watch(budgetStreamProvider);
  final preferredCurrency = ref.watch(currencySettingsProvider);
  final ratesAsync = ref.watch(exchangeRatesProvider(preferredCurrency));

  return budgetAsync.when(
    data: (budget) {
      if (budget == null) return const AsyncValue.data(null);
      if (budget.currency == preferredCurrency) return AsyncValue.data(budget);

      return ratesAsync.when(
        data: (rates) {
          final rate = rates[budget.currency];
          if (rate == null) return AsyncValue.data(budget);
          return AsyncValue.data(BudgetModel(
            limit: budget.limit / rate,
            currency: preferredCurrency,
            period: budget.period,
          ));
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.data(budget), // Retourne le budget original en cas d'erreur
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
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

    final currentCurrency = ref.read(currencySettingsProvider);

    try {
      await ref.read(budgetRepositoryProvider).setBudget(
        BudgetModel(limit: limit, currency: currentCurrency)
      );
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
    final budgetAsync = ref.watch(convertedBudgetProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budget)),
      body: budgetAsync.when(
        data: (budget) {
          if (budget != null && _limitController.text.isEmpty) {
            _limitController.text = budget.limit.toStringAsFixed(2);
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
                    suffixText: ref.watch(currencySymbolProvider),
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
