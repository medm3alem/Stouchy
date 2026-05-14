import 'dart:convert';
import 'package:http/http.dart' as http;
import '../transactions/domain/transaction.dart';

class GeminiService {
  static const _hardcodedApiKey = '';

  static Future<String> analyzeFinances({
    String? apiKey,
    required List<TransactionModel> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpense,
    String language = "français",
    String currencySymbol = "€",
  }) async {
    final effectiveKey = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : _hardcodedApiKey;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      // Regrouper par catégorie pour économiser des tokens
      final categoryTotals = <String, double>{};
      for (var t in transactions.take(30)) {
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      }
      final txsSummary = categoryTotals.entries.map((e) => "- ${e.key}: ${e.value.toStringAsFixed(2)}$currencySymbol").join("\n");

      final prompt = "Tu es le Conseiller Financier Stouchy. Analyse ce résumé mensuel :\n"
          "Solde: ${balance}$currencySymbol | Revenus: ${totalIncome}$currencySymbol | Dépenses: ${totalExpense}$currencySymbol\n"
          "DÉPENSES PAR CATÉGORIE :\n$txsSummary\n\n"
          "CONTEXTE ET RÈGLES :\n"
          "1. Identifie les dépenses INCOMPRESSIBLES et ne propose JAMAIS de les réduire.\n"
          "2. Ton conseil doit être DIRECT et RAISONNABLE.\n"
          "Réponds en $language, max 25 mots.";

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant', // Modèle avec des limites de tokens bien plus élevées
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 100,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      }
      return "Prêt à analyser vos finances.";
    } catch (e) {
      return "Besoin d'un conseil ? Je suis là.";
    }
  }

  static Future<String> generateMonthlyReport({
    String? apiKey,
    required List<TransactionModel> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpense,
    String language = "français",
    String currencySymbol = "€",
    required String monthYear,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : _hardcodedApiKey;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final categoryTotals = <String, double>{};
      for (var t in transactions) {
        categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
      }
      
      final categorySummary = categoryTotals.entries
        .map((e) => "- ${e.key}: ${e.value.toStringAsFixed(2)}$currencySymbol")
        .join("\n");

      final prompt = "Tu es le Conseiller Financier expert de l'application Stouchy. "
          "Génère un rapport mensuel détaillé pour le mois de $monthYear.\n"
          "DONNÉES :\n"
          "- Solde actuel : $balance$currencySymbol\n"
          "- Total Revenus : $totalIncome$currencySymbol\n"
          "- Total Dépenses : $totalExpense$currencySymbol\n"
          "DÉPENSES PAR CATÉGORIE :\n$categorySummary\n\n"
          "STRUCTURE DU RAPPORT :\n"
          "1. Analyse globale de la santé financière (distingue bien besoins essentiels et envies).\n"
          "2. Points positifs.\n"
          "3. Domaines d'amélioration (ne suggère JAMAIS de réduire le logement ou la santé, concentre-toi sur le superflu).\n"
          "4. Un conseil concret, direct et raisonnable pour le mois prochain.\n\n"
          "Ton ton doit être encourageant, professionnel et concis (max 150 mots). "
          "Réponds en $language.";

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      }
      return "Analyse mensuelle indisponible pour le moment.";
    } catch (e) {
      return "Erreur lors de la génération du rapport : $e";
    }
  }

  static Future<String?> predictCategory({
    required String title,
    required List<String> categories,
  }) async {
    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final prompt = "Choisis la catégorie la plus adaptée pour la transaction nommée \"$title\" "
          "parmi cette liste uniquement : ${categories.join(', ')}. "
          "Réponds seulement par le nom de la catégorie, sans ponctuation ni explication.";

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_hardcodedApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0,
          'max_tokens': 20,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prediction = data['choices'][0]['message']['content'].toString().trim();
        final cleanPrediction = prediction.replaceAll('"', '').replaceAll("'", "");
        if (categories.contains(cleanPrediction)) return cleanPrediction;
      }
    } catch (_) {}
    return null;
  }
}
