import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/transaction.dart';
import '../data/transaction_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

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

  final List<String> _categories = [
    'Alimentation', 'Transport', 'Loisirs', 'Santé', 
    'Logement', 'Salaire', 'Cadeau', 'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType == 'income' ? TransactionType.income : TransactionType.expense;
    if (_type == TransactionType.income) _selectedCategory = 'Salaire';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (userId == null) return;

    final transaction = TransactionModel(
      id: '', // Firestore générera l'ID
      userId: userId,
      title: _titleController.text,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      category: _selectedCategory,
      type: _type,
    );

    try {
      await ref.read(transactionRepositoryProvider).addTransaction(transaction);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.expense),
      );
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
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '0.00 €',
                  border: InputBorder.none,
                ),
                validator: (v) => v!.isEmpty ? 'Entrez un montant' : null,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  prefixIcon: Icon(Icons.title),
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
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _type == TransactionType.income ? AppColors.income : AppColors.expense,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
