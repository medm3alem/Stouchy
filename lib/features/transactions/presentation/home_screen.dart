import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stouchy/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/recurring_provider.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/widgets/balance_card.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../../shared/widgets/budget_progress_bar.dart';
import '../../../features/ai/ai_advice_widget.dart';

import '../../../features/auth/providers/profile_provider.dart';
import 'dart:io';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Déclencher le traitement des transactions récurrentes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recurringProcessorProvider).processPendingTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final txsAsync = ref.watch(transactionsProvider);
    final balance = ref.watch(balanceProvider);
    final income = ref.watch(totalIncomeProvider);
    final expense = ref.watch(totalExpenseProvider);
    final localImagePath = ref.watch(profilePhotoProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Forcé pour éviter le décalage sur certains appareils
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: localImagePath != null && File(localImagePath).existsSync()
                    ? FileImage(File(localImagePath))
                    : null,
                child: (localImagePath == null || !File(localImagePath).existsSync())
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        ),
        title: Text(
          l10n.appTitle, 
          style: const TextStyle(
            fontWeight: FontWeight.w800, 
            letterSpacing: 1.2,
            fontSize: 22,
          )
        ),
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
          data: (_) {
            final txs = ref.watch(convertedTransactionsProvider);
            return SingleChildScrollView(
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
                  const SizedBox(height: 16),

                  // ── Barre de Budget ────────────────────────────
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: const BudgetProgressBar(),
                  ),
                  const SizedBox(height: 20),

                  // ── Boutons rapides ────────────────────────────
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  ),
                  const SizedBox(height: 20),

                  // ── Conseil IA ─────────────────────────────────
                  if (txs.isNotEmpty) ...[
                    const AiAdviceWidget(),
                    const SizedBox(height: 20),
                  ],

                  // ── Outils (Convertisseur) ─────────────────────
                  FadeInRight(
                    delay: const Duration(milliseconds: 300),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.currency_exchange, color: AppColors.primary),
                        title: const Text('Convertisseur de Devises', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Calculez vos transferts instantanément'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/currency-converter'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => FadeInUp(
                        delay: Duration(milliseconds: 100 * i),
                        child: TransactionTile(transaction: txs[i]),
                      ),
                    ),
                  const SizedBox(height: 100), // Espace pour ne pas être caché par le FAB ou la barre système
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        tooltip: AppLocalizations.of(context)!.addTransaction,
        child: const Icon(Icons.add, color: Colors.white),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label, 
                style: TextStyle(
                  color: isDark ? color.withOpacity(0.9) : color, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
