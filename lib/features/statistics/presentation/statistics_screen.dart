import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import '../../reports/report_service.dart';
import '../../ai/gemini_service.dart';
import '../../ai/ai_provider.dart';

enum ChartView { pie, line }

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  TransactionType _selectedType = TransactionType.expense;
  ChartView _selectedView = ChartView.pie;
  bool _isGeneratingReport = false;

  Future<void> _generatePdfReport() async {
    setState(() => _isGeneratingReport = true);
    
    try {
      final transactions = ref.read(convertedTransactionsProvider);
      final balance = ref.read(balanceProvider);
      final income = ref.read(totalIncomeProvider);
      final expense = ref.read(totalExpenseProvider);
      final currencySymbol = ref.read(currencySymbolProvider);
      final apiKey = ref.read(aiApiKeyProvider);
      final locale = ref.read(localeProvider);
      
      final monthYear = DateFormat.yMMMM(locale.languageCode).format(DateTime.now());
      
      // Filtrer les dépenses par catégorie pour le rapport
      final expenseTxs = transactions.where((t) => t.type == TransactionType.expense).toList();
      final Map<String, double> categoryData = {};
      for (var t in expenseTxs) {
        categoryData[t.category] = (categoryData[t.category] ?? 0) + t.amount;
      }

      // 1. Obtenir l'analyse AI
      final aiAdvice = await GeminiService.generateMonthlyReport(
        apiKey: apiKey,
        transactions: transactions,
        balance: balance,
        totalIncome: income,
        totalExpense: expense,
        monthYear: monthYear,
        currencySymbol: currencySymbol,
        language: locale.languageCode == 'fr' ? 'français' : 'english',
      );

      // 2. Générer le PDF
      await ReportService.generateAndDownloadReport(
        monthYear: monthYear,
        balance: balance,
        totalIncome: income,
        totalExpense: expense,
        categoryData: categoryData,
        aiAdvice: aiAdvice,
        currencySymbol: currencySymbol,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport PDF généré avec succès ✓'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du rapport : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.statistics),
        actions: [
          if (_isGeneratingReport)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Télécharger le rapport mensuel',
              onPressed: _generatePdfReport,
            ),
          IconButton(
            icon: Icon(_selectedView == ChartView.pie ? Icons.show_chart : Icons.pie_chart),
            onPressed: () {
              setState(() {
                _selectedView = _selectedView == ChartView.pie ? ChartView.line : ChartView.pie;
              });
            },
          )
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (_) {
          // Utiliser les transactions converties
          final transactions = ref.watch(convertedTransactionsProvider);
          if (transactions.isEmpty) return _buildEmptyState(l10n);

          final filteredTxs = transactions.where((t) => t.type == _selectedType).toList();
          final Map<String, double> dataMap = {};
          double total = 0;
          for (var t in filteredTxs) {
            dataMap[t.category] = (dataMap[t.category] ?? 0) + t.amount;
            total += t.amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur Dépense/Revenu
                FadeInDown(
                  duration: const Duration(milliseconds: 400),
                  child: Center(
                    child: SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(value: TransactionType.expense, label: Text(l10n.expense), icon: const Icon(Icons.trending_down)),
                        ButtonSegment(value: TransactionType.income, label: Text(l10n.income), icon: const Icon(Icons.trending_up)),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (newSelection) => setState(() => _selectedType = newSelection.first),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Carte résumé
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildSummaryCard(total, _selectedType, currencySymbol),
                ),
                const SizedBox(height: 24),

                // Graphique
                FadeIn(
                  delay: const Duration(milliseconds: 400),
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: _selectedView == ChartView.pie 
                      ? _buildPieChart(dataMap, total, l10n)
                      : _buildLineChart(filteredTxs),
                  ),
                ),
                const SizedBox(height: 32),

                // Détails par catégorie
                if (_selectedView == ChartView.pie)
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Détails par catégorie', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...dataMap.entries.map((entry) => _CategoryTile(
                          category: entry.key,
                          amount: entry.value,
                          total: total,
                          color: _getCategoryColor(entry.key),
                          currencySymbol: currencySymbol,
                        )).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> dataMap, double total, AppLocalizations l10n) {
    if (dataMap.isEmpty) return const Center(child: Text('Pas de données'));
    return Column(
      children: [
        Text(_selectedType == TransactionType.expense ? l10n.expenseByCategory : 'Revenus par catégorie', 
             style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 20),
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: dataMap.entries.map((entry) {
                final color = _getCategoryColor(entry.key);
                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: '${((entry.value / total) * 100).toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<TransactionModel> txs) {
    if (txs.isEmpty) return const Center(child: Text('Pas de données'));
    
    // Grouper par jour
    final Map<DateTime, double> dailyData = {};
    for (var t in txs) {
      final date = DateTime(t.date.year, t.date.month, t.date.day);
      dailyData[date] = (dailyData[date] ?? 0) + t.amount;
    }
    
    final sortedDates = dailyData.keys.toList()..sort();
    if (sortedDates.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyData[sortedDates[i]]!));
    }

    return Column(
      children: [
        const Text('Évolution temporelle', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 20),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                        if (value % (sortedDates.length > 5 ? (sortedDates.length / 5).ceil() : 1) == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('dd/MM').format(sortedDates[value.toInt()]), style: const TextStyle(fontSize: 10)),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: _selectedType == TransactionType.income ? AppColors.income : AppColors.expense,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: (_selectedType == TransactionType.income ? AppColors.income : AppColors.expense).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(double total, TransactionType type, String currencySymbol) {
    final color = type == TransactionType.income ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 25, child: Icon(type == TransactionType.income ? Icons.trending_up : Icons.trending_down, color: Colors.white)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type == TransactionType.income ? 'Revenus totaux' : 'Dépenses totales', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              Text('${total.toStringAsFixed(2)} $currencySymbol', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(l10n.noTransactions, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.cyan, Colors.teal, Colors.pink, Colors.indigo, Colors.amber];
    final index = category.length + (category.isNotEmpty ? category.codeUnitAt(0) : 0);
    return colors[index % colors.length];
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  final Color color;
  final String currencySymbol;
  const _CategoryTile({required this.category, required this.amount, required this.total, required this.color, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final percentage = (amount / total) * 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          Container(width: 12, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: amount / total, backgroundColor: Colors.grey[100], color: color, minHeight: 6)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${amount.toStringAsFixed(2)} $currencySymbol', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
