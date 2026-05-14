import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../transactions/providers/transaction_provider.dart';
import 'gemini_service.dart';
import 'ai_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../../core/theme/app_theme.dart';

final aiAdviceProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  final currentLocale = ref.watch(localeProvider);
  final currencySymbol = ref.watch(currencySymbolProvider);

  String languageName = "français";
  if (currentLocale.languageCode == 'en') languageName = "anglais";
  if (currentLocale.languageCode == 'ar') languageName = "arabe";
  
  final transactions = ref.watch(convertedTransactionsProvider);
  final balance = ref.watch(balanceProvider);
  final income = ref.watch(totalIncomeProvider);
  final expense = ref.watch(totalExpenseProvider);

  if (transactions.isEmpty) {
    if (currentLocale.languageCode == 'en') return "Add your first transactions to get personalized advice!";
    if (currentLocale.languageCode == 'ar') return "أضف معاملاتك الأولى للحصول على نصائح مخصصة!";
    return "Ajoutez vos premières transactions pour recevoir mes conseils !";
  }

  return await GeminiService.analyzeFinances(
    apiKey: apiKey,
    transactions: transactions,
    balance: balance,
    totalIncome: income,
    totalExpense: expense,
    language: languageName,
    currencySymbol: currencySymbol,
  );
});

class AiAdviceWidget extends ConsumerWidget {
  const AiAdviceWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adviceAsync = ref.watch(aiAdviceProvider);

    return adviceAsync.when(
      data: (advice) => _buildAdviceCard(advice, context),
      loading: () => _buildLoadingCard(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildAdviceCard(String advice, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
            AppColors.primary.withOpacity(isDark ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => context.push('/chat-ai'),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Conseiller Stouchy AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                advice,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Cliquez pour plus de détails',
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 16),
          Text(
            "Analyse en cours par Stouchy AI...", 
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
