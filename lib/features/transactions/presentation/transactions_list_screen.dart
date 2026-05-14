import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/transaction.dart';
import '../providers/transaction_provider.dart';
import '../../../shared/widgets/transaction_tile.dart';

class TransactionsListScreen extends ConsumerWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Toutes les transactions'),
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (_) {
          final transactions = ref.watch(convertedTransactionsProvider);
          if (transactions.isEmpty) {
            return const Center(child: Text('Aucune transaction trouvée'));
          }

          // Grouper les transactions par date
          final groupedTransactions = <DateTime, List<TransactionModel>>{};
          for (var tx in transactions) {
            final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
            if (groupedTransactions[date] == null) {
              groupedTransactions[date] = [];
            }
            groupedTransactions[date]!.add(tx);
          }

          final sortedDates = groupedTransactions.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
            itemCount: sortedDates.length,
            itemBuilder: (context, dateIndex) {
              final date = sortedDates[dateIndex];
              final dateTxs = groupedTransactions[date]!;
              final isToday = DateTime.now().year == date.year && 
                              DateTime.now().month == date.month && 
                              DateTime.now().day == date.day;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      isToday ? "Aujourd'hui" : DateFormat.yMMMMd('fr_FR').format(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                  ...dateTxs.map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TransactionTile(transaction: tx),
                  )),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
