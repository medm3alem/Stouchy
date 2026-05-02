import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../transactions/providers/transaction_provider.dart';
import 'gemini_service.dart';
import 'ai_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';

final aiAdviceProvider = FutureProvider<String>((ref) async {
  final apiKey = ref.watch(aiApiKeyProvider);
  final currentLocale = ref.watch(localeProvider);

  String languageName = "français";
  if (currentLocale.languageCode == 'en') languageName = "anglais";
  if (currentLocale.languageCode == 'ar') languageName = "arabe";
  
  final transactions = ref.watch(transactionsProvider).value ?? [];
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
    return InkWell(
      onTap: () => context.push('/chat-ai'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Conseil Stouchy AI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advice,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tapotez pour discuter avec l\'IA',
                    style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 16),
          Text("L'IA analyse vos finances...", style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
