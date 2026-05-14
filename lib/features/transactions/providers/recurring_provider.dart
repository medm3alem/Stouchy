import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recurring_repository.dart';
import '../data/transaction_repository.dart';
import '../domain/transaction.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/providers/currency_settings_provider.dart';

final recurringTransactionsProvider = StreamProvider<List<RecurringTransactionModel>>((ref) {
  return ref.watch(recurringRepositoryProvider).getRecurring();
});

final recurringProcessorProvider = Provider((ref) {
  final recurringRepo = ref.watch(recurringRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  
  return RecurringProcessor(recurringRepo, transactionRepo);
});

class RecurringProcessor {
  final RecurringTransactionRepository _recurringRepo;
  final TransactionRepository _transactionRepo;

  RecurringProcessor(this._recurringRepo, this._transactionRepo);

  Future<void> processPendingTransactions() async {
    // Récupération asynchrone simplifiée
    final snapshot = await _recurringRepo.getRecurring().first;
    if (snapshot.isEmpty) return;
    
    final now = DateTime.now();

    for (var rec in snapshot) {
      DateTime nextDueDate = _calculateNextDueDate(rec);
      
      while (nextDueDate.isBefore(now) || _isSameDay(nextDueDate, now)) {
        final newTx = TransactionModel(
          id: '',
          userId: rec.userId,
          title: rec.title,
          amount: rec.amount,
          currency: rec.currency,
          date: nextDueDate,
          category: rec.category,
          type: rec.type,
          note: 'Automatique',
          recurringFrequency: rec.frequency,
          recurringId: rec.id,
        );

        await _transactionRepo.addTransaction(newTx);
        await _recurringRepo.updateLastProcessed(rec.id, nextDueDate);
        
        // Notification immédiate
        NotificationService.showRecurringTransactionAlert(
          title: rec.title,
          amount: rec.amount,
          symbol: getCurrencySymbol(rec.currency),
          isExpense: rec.type == TransactionType.expense,
        );
        
        nextDueDate = _calculateNextDate(nextDueDate, rec.frequency);
      }

      // Programmer la suivante de manière non-bloquante
      NotificationService.scheduleRecurringNotification(
        id: rec.id.hashCode,
        title: rec.title,
        amount: rec.amount,
        symbol: getCurrencySymbol(rec.currency),
        scheduledDate: nextDueDate,
        isExpense: rec.type == TransactionType.expense,
      ).catchError((_) {}); // Ignorer les erreurs de scheduling pour la fluidité
    }
  }

  DateTime _calculateNextDueDate(RecurringTransactionModel rec) {
    if (rec.lastProcessedDate == null) {
      return rec.startDate;
    }
    return _calculateNextDate(rec.lastProcessedDate!, rec.frequency);
  }

  DateTime _calculateNextDate(DateTime from, RecurringFrequency frequency) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurringFrequency.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
