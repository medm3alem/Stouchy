import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencySettingsNotifier extends StateNotifier<String> {
  CurrencySettingsNotifier() : super('EUR') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('preferred_currency') ?? 'EUR';
  }

  Future<void> setCurrency(String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_currency', currencyCode);
    state = currencyCode;
  }
}

final currencySettingsProvider = StateNotifierProvider<CurrencySettingsNotifier, String>((ref) {
  return CurrencySettingsNotifier();
});

String getCurrencySymbol(String currencyCode) {
  switch (currencyCode) {
    case 'USD':
    case 'CAD':
    case 'AUD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'JPY':
    case 'CNY':
      return '¥';
    case 'MAD':
      return 'DH';
    case 'DZD':
      return 'DA';
    case 'TND':
      return 'DT';
    case 'CHF':
      return 'CHF';
    default:
      return currencyCode;
  }
}

const Map<String, String> currencyLogos = {
  'EUR': '🇪🇺',
  'USD': '🇺🇸',
  'GBP': '🇬🇧',
  'JPY': '🇯🇵',
  'CAD': '🇨🇦',
  'AUD': '🇦🇺',
  'CHF': '🇨🇭',
  'CNY': '🇨🇳',
  'MAD': '🇲🇦',
  'DZD': '🇩🇿',
  'TND': '🇹🇳'
};

final currencySymbolProvider = Provider<String>((ref) {
  final currency = ref.watch(currencySettingsProvider);
  return getCurrencySymbol(currency);
});
