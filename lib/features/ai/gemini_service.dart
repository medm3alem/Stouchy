import 'dart:convert';
import 'package:http/http.dart' as http;
import '../transactions/domain/transaction.dart';

class GeminiService {
  static const _hardcodedApiKey = 'AIzaSyDGEuo0zjL0uZgYJNGgf-j3bs4hm82YGpw';

  static Future<String> analyzeFinances({
    String? apiKey,
    required List<TransactionModel> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final effectiveKey = (apiKey != null && apiKey.isNotEmpty) ? apiKey : _hardcodedApiKey;
    
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$effectiveKey');

      final prompt = "En tant qu'expert finance Stouchy, donne un conseil de 20 mots max en français basé sur ces chiffres : Solde ${balance}€, Revenus ${totalIncome}€, Dépenses ${totalExpense}€.";

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
      }
      return "Prêt à analyser vos finances.";
    } catch (e) {
      return "Besoin d'un conseil ? Je suis là.";
    }
  }
}
