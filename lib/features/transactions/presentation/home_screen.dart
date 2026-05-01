import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/widgets/balance_card.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../features/ai/ai_advice_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final txsAsync = ref.watch(transactionsProvider);
    final balance = ref.watch(balanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.bar_chart), onPressed: () => context.push('/statistics')),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(transactionsProvider),
        child: txsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (txs) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Carte solde animée ─────────────────────────
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: BalanceCard(balance: balance, income: income, expense: expense),
                ),
                const SizedBox(height: 20),

                // ── Boutons rapides ────────────────────────────
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Expanded(child: _QuickBtn(
                          label: l10n.addIncome, icon: Icons.add_circle,
                          color: AppColors.income,
                          onTap: () => context.push('/add-transaction?type=income'))),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickBtn(
                          label: l10n.addExpense, icon: Icons.remove_circle,
                          color: AppColors.expense,
                          onTap: () => context.push('/add-transaction?type=expense'))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Conseil IA ─────────────────────────────────
                if (txs.isNotEmpty) ...[
                  const AiAdviceWidget(),
                  const SizedBox(height: 20),
                ],

                // ── Transactions récentes ──────────────────────
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.recentTransactions,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => context.push('/transactions'), child: Text(l10n.viewAll)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                if (txs.isEmpty)
                  FadeIn(
                    child: Center(
                      child: Column(
                        children: [
                          // Animation Lottie vide
                          SizedBox(
                            height: 160,
                            child: Lottie.network(
                              'https://assets2.lottiefiles.com/packages/lf20_szviypry.json',
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.inbox, size: 64, color: AppColors.textSec.withOpacity(0.5)),
                            ),
                          ),
                          Text(l10n.noTransactions,
                              style: TextStyle(color: AppColors.textSec)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.take(5).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => FadeInUp(
                      delay: Duration(milliseconds: 100 * i),
                      child: TransactionTile(transaction: txs[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addTransaction),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}