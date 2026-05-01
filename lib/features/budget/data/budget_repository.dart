import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return BudgetRepository(FirebaseFirestore.instance, auth.currentUser?.uid);
});

class BudgetRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;

  BudgetRepository(this._firestore, this._userId);

  DocumentReference get _budgetRef =>
      _firestore.collection('users').doc(_userId).collection('settings').doc('budget');

  Future<void> setBudget(BudgetModel budget) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    await _budgetRef.set(budget.toMap());
  }

  Stream<BudgetModel?> getBudget() {
    if (_userId == null) return Stream.value(null);
    return _budgetRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return BudgetModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }
}
