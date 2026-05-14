import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final exchangeRatesProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, baseCurrency) async {
  final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency');
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body)['rates'];
  } else {
    throw Exception('Failed to load exchange rates');
  }
});

class CurrencyConverterNotifier extends StateNotifier<AsyncValue<double>> {
  CurrencyConverterNotifier() : super(const AsyncValue.data(0.0));

  void convert({
    required double amount,
    required String from,
    required String to,
    required Map<String, dynamic> rates,
  }) {
    final fromRate = rates[from];
    final toRate = rates[to];
    
    if (fromRate != null && toRate != null) {
      final result = (amount / fromRate) * toRate;
      state = AsyncValue.data(result);
    } else {
      state = AsyncValue.error('Devise non supportée', StackTrace.current);
    }
  }
}

final currencyConverterProvider = StateNotifierProvider<CurrencyConverterNotifier, AsyncValue<double>>((ref) {
  return CurrencyConverterNotifier();
});
