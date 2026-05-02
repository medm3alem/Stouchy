import 'dart:convert';
import 'package:http/http.dart' as http;
import '../transactions/domain/transaction.dart';

class GeminiService {
  static const _hardcodedApiKey = ''; // Masqué pour GitHub

  static Future<String> analyzeFinances({
    String? apiKey,
    required List<TransactionModel> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpense,
    String language = "français",
  }) async {
    final effectiveKey = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : _hardcodedApiKey;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      // Préparation du détail des transactions pour l'IA
      final txsSummary = transactions.take(20).map((t) => 
        "- ${t.type == TransactionType.income ? '+' : '-'}${t.amount}€: ${t.title} (${t.category})"
      ).join("\n");

      final prompt = "Tu es l'expert financier Stouchy. Analyse ces données :\n"
          "Solde: ${balance}€ | Revenus: ${totalIncome}€ | Dépenses: ${totalExpense}€\n"
          "Dernières transactions :\n$txsSummary\n\n"
          "Donne un conseil ultra-court (max 20 mots) en $language, très précis sur une habitude détectée.";

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 100,
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
        // Nettoyage au cas où l'IA ajoute des guillemets
        final cleanPrediction = prediction.replaceAll('"', '').replaceAll("'", "");
        if (categories.contains(cleanPrediction)) return cleanPrediction;
      }
    } catch (_) {}
    return null;
  }
}
