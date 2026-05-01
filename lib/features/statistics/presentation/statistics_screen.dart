import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../core/theme/app_theme.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyses des dépenses')),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (transactions) {
          final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
          
          if (expenses.isEmpty) {
            return const Center(child: Text('Aucune dépense à analyser'));
          }

          // Grouper par catégorie
          final Map<String, double> dataMap = {};
          for (var t in expenses) {
            dataMap[t.category] = (dataMap[t.category] ?? 0) + t.amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Répartition par catégorie',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _getSections(dataMap),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Liste détaillée
                ...dataMap.entries.map((entry) => _CategoryTile(
                  category: entry.key,
                  amount: entry.value,
                  total: expenses.fold(0, (sum, t) => sum + t.amount),
                )).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _getSections(Map<String, double> data) {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.yellow];
    int i = 0;
    return data.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: entry.key,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double total;

  const _CategoryTile({required this.category, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = (amount / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: amount / total,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${amount.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
