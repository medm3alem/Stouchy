import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/transaction.dart';

final recurringRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return RecurringTransactionRepository(FirebaseFirestore.instance, auth.currentUser?.uid);
});

class RecurringTransactionRepository {
  final FirebaseFirestore _firestore;
  final String? _userId;

  RecurringTransactionRepository(this._firestore, this._userId);

  CollectionReference get _recurringRef =>
      _firestore.collection('users').doc(_userId).collection('recurring_transactions');

  Future<void> addRecurring(RecurringTransactionModel recurring) async {
    if (_userId == null) throw Exception('Utilisateur non connecté');
    await _recurringRef.add(recurring.toMap());
  }

  Stream<List<RecurringTransactionModel>> getRecurring() {
    if (_userId == null) return Stream.value([]);
    return _recurringRef
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecurringTransactionModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateLastProcessed(String id, DateTime date) async {
    await _recurringRef.doc(id).update({'lastProcessedDate': Timestamp.fromDate(date)});
  }

  Future<void> deleteRecurring(String id) async {
    await _recurringRef.doc(id).delete();
  }
}
