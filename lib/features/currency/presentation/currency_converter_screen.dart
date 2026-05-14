import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/currency_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/currency_settings_provider.dart';

class CurrencyConverterScreen extends ConsumerStatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  ConsumerState<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends ConsumerState<CurrencyConverterScreen> {
  final TextEditingController _amountController = TextEditingController(text: '1');
  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onConvert() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final ratesAsync = ref.read(exchangeRatesProvider(_fromCurrency));
    
    ratesAsync.whenData((rates) {
      ref.read(currencyConverterProvider.notifier).convert(
        amount: amount,
        from: _fromCurrency,
        to: _toCurrency,
        rates: rates,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesProvider(_fromCurrency));
    final resultAsync = ref.watch(currencyConverterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertisseur de Devises'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeInDown(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Montant à convertir',
                          hintText: 'Entrez un montant',
                        ),
                        onChanged: (_) => _onConvert(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildCurrencyDropdown(
                              label: 'De',
                              value: _fromCurrency,
                              onChanged: (val) {
                                setState(() => _fromCurrency = val!);
                                _onConvert();
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: IconButton(
                              icon: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 24),
                              onPressed: () {
                                setState(() {
                                  final temp = _fromCurrency;
                                  _fromCurrency = _toCurrency;
                                  _toCurrency = temp;
                                });
                                _onConvert();
                              },
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: _buildCurrencyDropdown(
                              label: 'Vers',
                              value: _toCurrency,
                              onChanged: (val) {
                                setState(() => _toCurrency = val!);
                                _onConvert();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ratesAsync.when(
              data: (rates) {
                return FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Résultat',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        resultAsync.when(
                          data: (result) => Text(
                            '${result.toStringAsFixed(2)} $_toCurrency',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text('Erreur: $e'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1 $_fromCurrency = ${(rates[_toCurrency] ?? 0).toStringAsFixed(4)} $_toCurrency',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Impossible de récupérer les taux de change : $e'),
                    TextButton(
                      onPressed: () => ref.refresh(exchangeRatesProvider(_fromCurrency)),
                      child: const Text('Réessayer'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: currencyLogos.entries.map((e) {
                return DropdownMenuItem(
                  value: e.key, 
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  )
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
