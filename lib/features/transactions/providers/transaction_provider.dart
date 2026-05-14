import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../currency/providers/currency_provider.dart';

// Stream de toutes les transactions
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

// Transactions converties dans la devise préférée
final convertedTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? [];
  final preferredCurrency = ref.watch(currencySettingsProvider);
  final ratesAsync = ref.watch(exchangeRatesProvider(preferredCurrency));

  return ratesAsync.when(
    data: (rates) {
      return txs.map((tx) {
        if (tx.currency == preferredCurrency) return tx;
        final rate = rates[tx.currency];
        if (rate == null) return tx;
        return TransactionModel(
          id: tx.id,
          userId: tx.userId,
          title: tx.title,
          amount: tx.amount / rate,
          currency: preferredCurrency,
          date: tx.date,
          category: tx.category,
          type: tx.type,
          note: tx.note,
        );
      }).toList();
    },
    loading: () => txs, // Retourne les transactions originales en attendant les taux
    error: (_, __) => txs,
  );
});

// Calcul du Solde Total
final balanceProvider = Provider<double>((ref) {
  final txs = ref.watch(convertedTransactionsProvider);
  return txs.fold(0.0, (sum, item) => item.type == TransactionType.income 
      ? sum + item.amount 
      : sum - item.amount);
});

// Calcul des Revenus Totaux
final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(convertedTransactionsProvider);
  return txs
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);
});

// Calcul des Dépenses Totales (Historique complet)
final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(convertedTransactionsProvider);
  return txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);
});

// Calcul des Dépenses du MOIS EN COURS
final currentMonthExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(convertedTransactionsProvider);
  final now = DateTime.now();
  return txs
      .where((t) => 
          t.type == TransactionType.expense && 
          t.date.month == now.month && 
          t.date.year == now.year)
      .fold(0.0, (sum, item) => sum + item.amount);
});
