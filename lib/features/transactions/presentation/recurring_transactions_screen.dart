import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/transaction.dart';
import '../providers/recurring_provider.dart';
import '../data/recurring_repository.dart';
import '../data/transaction_repository.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

class RecurringTransactionsScreen extends ConsumerWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Transactions Récurrentes'),
      ),
      body: recurringAsync.when(
        data: (list) => list.isEmpty 
          ? const Center(child: Text('Aucune transaction récurrente'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final rec = list[index];
                return _RecurringTile(recurring: rec);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-recurring'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _RecurringTile extends ConsumerWidget {
  final RecurringTransactionModel recurring;
  const _RecurringTile({required this.recurring});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = recurring.type == TransactionType.expense;
    final symbol = getCurrencySymbol(recurring.currency);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
          child: Icon(
            isExpense ? Icons.repeat : Icons.repeat_on,
            color: isExpense ? Colors.red : Colors.green,
          ),
        ),
        title: Text(recurring.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${recurring.frequency.name.toUpperCase()} • ${recurring.category}'),
            Text('Début : ${DateFormat.yMd().format(recurring.startDate)}', style: const TextStyle(fontSize: 10)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isExpense ? "-" : "+"}${recurring.amount.toStringAsFixed(2)} $symbol',
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recurring.lastProcessedDate != null)
              Text(
                'Dernier : ${DateFormat.yMd().format(recurring.lastProcessedDate!)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        onLongPress: () => _showDeleteConfirm(context, ref),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
    DateTime deleteFromDate = recurring.startDate;
    bool isLoading = false;
    
    // On capture les repositories AVANT l'async pour éviter l'erreur "ref after dispose"
    final recurringRepo = ref.read(recurringRepositoryProvider);
    final transactionRepo = ref.read(transactionRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setLocalState) => AlertDialog(
          title: const Text("Supprimer la récurrence"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Voulez-vous arrêter '${recurring.title}' ?"),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Supprimer aussi les transactions déjà créées ?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !isLoading,
                title: Text(
                  "Depuis le : ${DateFormat.yMd().format(deleteFromDate)}",
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: const Icon(Icons.calendar_month, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogCtx,
                    initialDate: deleteFromDate,
                    firstDate: recurring.startDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setLocalState(() => deleteFromDate = picked);
                  }
                },
              ),
              const Text(
                "Note : Cela supprimera toutes les occurrences automatiques générées après cette date.",
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            // Option 1: Juste supprimer la règle
            TextButton(
              onPressed: isLoading ? null : () async {
                setLocalState(() => isLoading = true);
                try {
                  await recurringRepo.deleteRecurring(recurring.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  // On utilise le context de l'écran (qui est parent du dialogue)
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Récurrence arrêtée ✓"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
                    );
                  }
                  setLocalState(() => isLoading = false);
                }
              },
              child: const Text("Arrêter seulement"),
            ),
            // Option 2: Supprimer règle ET transactions
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
                foregroundColor: Colors.white,
              ),
              onPressed: isLoading ? null : () async {
                setLocalState(() => isLoading = true);
                try {
                  await recurringRepo.deleteRecurring(recurring.id);
                  await transactionRepo.deleteRecurringGeneratedTransactions(
                    recurring.id, 
                    deleteFromDate
                  );
                  
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Récurrence et transactions supprimées ✓"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
                    );
                  }
                  setLocalState(() => isLoading = false);
                }
              },
              child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Supprimer tout"),
            ),
          ],
        ),
      ),
    );
  }
}
