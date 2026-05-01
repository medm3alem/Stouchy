import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/transaction.dart';

final transactionRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return TransactionRepository(FirebaseFirestore.instance, auth.currentUser?.uid);
});

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;

  TransactionRepository(this._firestore, this._userId);

  CollectionReference get _transactionsRef =>
      _firestore.collection('users').doc(_userId).collection('transactions');

  // Ajouter une transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    await _transactionsRef.add(transaction.toMap());
  }

  // Récupérer toutes les transactions de l'utilisateur (temps réel)
  Stream<List<TransactionModel>> getTransactions() {
    if (_userId == null) return Stream.value([]);
    return _transactionsRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // Supprimer une transaction
  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  // Supprimer toutes les transactions (Vider l'historique)
  Future<void> deleteAllTransactions() async {
    if (_userId == null) return;
    final batch = _firestore.batch();
    final snapshots = await _transactionsRef.get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
