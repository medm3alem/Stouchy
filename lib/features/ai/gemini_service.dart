import 'package:google_generative_ai/google_generative_ai.dart';
import '../transactions/models/transaction_model.dart';

class GeminiService {
  // Remplacer par votre clé API Gemini
  // Obtenir sur : https://aistudio.google.com/app/apikey
  static const _apiKey = 'VOTRE_CLE_GEMINI_ICI';

  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  // Analyse financière personnalisée
  static Future<String> analyzeFinances({
    required List<TransactionModel> transactions,
    required double balance,
    required double monthlyExpense,
    required double? budgetLimit,
    String language = 'fr',
  }) async {
    final expenseByCategory = <String, double>{};
    for (final tx in transactions.where((t) => t.type == TransactionType.expense)) {
      expenseByCategory[tx.category] = (expenseByCategory[tx.category] ?? 0) + tx.amount;
    }

    final topCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final prompt = '''
Tu es un conseiller financier personnel expert. Analyse ces données et fournis des conseils personnalisés en ${language == 'fr' ? 'français' : language == 'ar' ? 'arabe' : 'anglais'}.

Données financières:
- Solde total: ${balance.toStringAsFixed(2)} TND
- Dépenses ce mois: ${monthlyExpense.toStringAsFixed(2)} TND
- Budget mensuel limite: ${budgetLimit?.toStringAsFixed(2) ?? 'Non défini'} TND
- Top catégories de dépenses: ${topCategories.take(3).map((e) => '${e.key}: ${e.value.toStringAsFixed(2)} TND').join(', ')}
- Nombre total de transactions: ${transactions.length}

Fournis:
1. Une analyse de la situation financière (2-3 phrases)
2. Le point positif principal
3. Le point d'amélioration principal  
4. Un conseil d'action concret pour cette semaine
5. Un score de santé financière sur 10

Format: réponse courte et claire, maximum 150 mots.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Analyse non disponible.';
    } catch (e) {
      return 'Service IA temporairement indisponible. Vérifiez votre connexion.';
    }
  }

  // Suggestion de catégorie automatique
  static Future<String> suggestCategory(String transactionTitle) async {
    final categories = ['Nourriture', 'Transport', 'Logement', 'Santé',
      'Loisirs', 'Shopping', 'Éducation', 'Salaire', 'Freelance', 'Autre'];
    final prompt = '''
Pour cette transaction: "$transactionTitle"
Choisir UNE seule catégorie parmi: ${categories.join(', ')}
Répondre avec le nom exact de la catégorie, rien d'autre.
''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final suggestion = response.text?.trim() ?? 'Autre';
      return categories.contains(suggestion) ? suggestion : 'Autre';
    } catch (_) {
      return 'Autre';
    }
  }
}