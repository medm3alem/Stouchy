import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/transaction.dart';
import '../data/recurring_repository.dart';
import '../providers/recurring_provider.dart';
import '../../ai/gemini_service.dart';
import '../../../core/providers/currency_settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

class AddRecurringScreen extends ConsumerStatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  ConsumerState<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends ConsumerState<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  TransactionType _type = TransactionType.expense;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _startDate = DateTime.now();
  String _selectedCategory = 'Abonnements';
  String _selectedCurrency = 'EUR';
  
  bool _isLoading = false;
  Timer? _debounce;
  bool _isPredicting = false;

  final List<String> _expenseCategories = [
    'Alimentation', 'Transport', 'Loisirs', 'Santé', 
    'Logement', 'Abonnements', 'Shopping', 'Autre'
  ];

  final List<String> _incomeCategories = [
    'Salaire', 'Cadeau', 'Vente', 'Intérêts', 'Autre'
  ];

  List<String> get _categories => _type == TransactionType.income ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(currencySettingsProvider);
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTitleChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () async {
      final title = _titleController.text.trim();
      if (title.length < 3) return;

      setState(() => _isPredicting = true);
      final prediction = await GeminiService.predictCategory(
        title: title,
        categories: _categories,
      );

      if (prediction != null && mounted) {
        setState(() {
          _selectedCategory = prediction;
          _isPredicting = false;
        });
      } else if (mounted) {
        setState(() => _isPredicting = false);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    setState(() => _isLoading = true);
    final userId = ref.read(authRepositoryProvider).currentUser?.uid ?? '';

    final recurring = RecurringTransactionModel(
      id: '',
      userId: userId,
      title: _titleController.text,
      amount: amount,
      currency: _selectedCurrency,
      category: _selectedCategory,
      type: _type,
      frequency: _frequency,
      startDate: _startDate,
    );

    try {
      await ref.read(recurringRepositoryProvider).addRecurring(recurring);
      // Déclencher le traitement immédiat
      await ref.read(recurringProcessorProvider).processPendingTransactions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Récurrence activée ✓')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Nouvelle Récurrence'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.expense, label: Text("Dépense"), icon: Icon(Icons.remove_circle_outline)),
                    ButtonSegment(value: TransactionType.income, label: Text("Revenu"), icon: Icon(Icons.add_circle_outline)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (val) {
                    setState(() {
                      _type = val.first;
                      _selectedCategory = _type == TransactionType.income ? 'Salaire' : 'Abonnements';
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    underline: const SizedBox(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                    items: currencyLogos.entries.map((e) => 
                      DropdownMenuItem(
                        value: e.key, 
                        child: Row(children: [Text(e.value), const SizedBox(width: 4), Text(e.key)])
                      )
                    ).toList(),
                    onChanged: (val) => setState(() => _selectedCurrency = val!),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  prefixIcon: const Icon(Icons.title),
                  suffixIcon: _isPredicting 
                    ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Entrez un titre' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie', prefixIcon: Icon(Icons.category)),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<RecurringFrequency>(
                value: _frequency,
                decoration: const InputDecoration(labelText: "Fréquence", prefixIcon: Icon(Icons.repeat)),
                items: RecurringFrequency.values.map((f) => 
                  DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()))
                ).toList(),
                onChanged: (val) => setState(() => _frequency = val!),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text('Date de début: ${DateFormat.yMMMd().format(_startDate)}'),
                leading: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _type == TransactionType.income ? AppColors.income : AppColors.expense,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer la récurrence', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
