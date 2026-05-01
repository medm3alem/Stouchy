import 'dart:convert';
import 'package:http/http.dart' as http;
import '../transactions/domain/transaction.dart';

class GeminiService {
  static const _hardcodedApiKey = ''; // REMOVE SECRET FOR GITHUB PUSH

  static Future<String> analyzeFinances({
    String? apiKey,
    required List<TransactionModel> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : _hardcodedApiKey;

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final prompt = "En tant qu'expert finance Stouchy, "
          "donne un conseil de 20 mots max en français basé sur ces chiffres : "
          "Solde ${balance}€, Revenus ${totalIncome}€, Dépenses ${totalExpense}€.";

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
}