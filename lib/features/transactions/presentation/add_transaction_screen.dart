import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/transaction.dart';
import '../data/transaction_repository.dart';
import '../providers/transaction_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../ai/gemini_service.dart';
import '../../budget/presentation/budget_screen.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:stouchy/l10n/app_localizations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialType;
  const AddTransactionScreen({super.key, this.initialType});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Alimentation';
  late TransactionType _type;
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
    _type = widget.initialType == 'income' ? TransactionType.income : TransactionType.expense;
    if (_type == TransactionType.income) {
      _selectedCategory = 'Salaire';
    } else {
      _selectedCategory = 'Alimentation';
    }
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

  Future<void> _checkBudgetAndNotify(double newAmount) async {
    try {
      // On récupère le budget actuel (on attend s'il le faut)
      final budgetAsync = ref.read(budgetStreamProvider);
      final budget = budgetAsync.value;
      
      // On récupère les dépenses déjà enregistrées ce mois-ci
      final currentExpense = ref.read(currentMonthExpenseProvider);
      
      if (budget != null && budget.limit > 0) {
        final totalAfter = currentExpense + newAmount;
        
        // On ne notifie que si cet achat précis nous fait passer au-dessus du budget
        if (totalAfter > budget.limit && currentExpense <= budget.limit) {
          await NotificationService.showBudgetAlert(totalAfter, budget.limit);
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la vérification du budget: $e");
    }
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
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    final userId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Utilisateur non connecté')),
      );
      return;
    }

    final transaction = TransactionModel(
      id: '', // Firestore générera l'ID
      userId: userId,
      title: _titleController.text,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      type: _type,
    );

    setState(() => _isLoading = true);
    
    // On lance la sauvegarde sans attendre la réponse du serveur (fire-and-forget)
    ref.read(transactionRepositoryProvider).addTransaction(transaction).catchError((e) {
      debugPrint("Erreur asynchrone Firestore: $e");
    });

    // Vérification du budget (on le fait en parallèle de la sauvegarde)
    if (transaction.type == TransactionType.expense) {
      _checkBudgetAndNotify(transaction.amount);
    }

    // On affiche immédiatement le succès et on quitte
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.transactionAdded ?? 'Transaction ajoutée ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_type == TransactionType.income ? 'Nouveau Revenu' : 'Nouvelle Dépense'),
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
                  segments: [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(AppLocalizations.of(context)!.expense),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text(AppLocalizations.of(context)!.income),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<TransactionType> newSelection) {
                    setState(() {
                      _type = newSelection.first;
                      _selectedCategory = _type == TransactionType.income ? 'Salaire' : 'Alimentation';
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '0.00 €',
                  border: InputBorder.none,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Entrez un montant';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Montant invalide';
                  return null;
                },
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
                validator: (v) => v!.isEmpty ? 'Entrez un titre' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                leading: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
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
                  : const Text('Enregistrer', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
