import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

// Stream de toutes les transactions
final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

// Calcul du Solde Total
final balanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? [];
  return txs.fold(0, (sum, item) => item.type == TransactionType.income 
      ? sum + item.amount 
      : sum - item.amount);
});

// Calcul des Revenus Totaux
final totalIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? [];
  return txs
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);
});

// Calcul des Dépenses Totales (Historique complet)
final totalExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? [];
  return txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);
});

// Calcul des Dépenses du MOIS EN COURS
final currentMonthExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider).value ?? [];
  final now = DateTime.now();
  return txs
      .where((t) => 
          t.type == TransactionType.expense && 
          t.date.month == now.month && 
          t.date.year == now.year)
      .fold(0.0, (sum, item) => sum + item.amount);
});
