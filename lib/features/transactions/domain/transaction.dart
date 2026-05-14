import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String? note;
  final RecurringFrequency? recurringFrequency;
  final String? recurringId;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    this.currency = 'EUR',
    required this.date,
    required this.category,
    required this.type,
    this.note,
    this.recurringFrequency,
    this.recurringId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'date': Timestamp.fromDate(date),
      'category': category,
      'type': type.name,
      'note': note,
      'recurringFrequency': recurringFrequency?.name,
      'recurringId': recurringId,
    };
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      note: data['note'],
      recurringFrequency: data['recurringFrequency'] != null 
          ? RecurringFrequency.values.firstWhere((e) => e.name == data['recurringFrequency'])
          : null,
      recurringId: data['recurringId'],
    );
  }
}

enum RecurringFrequency { daily, weekly, monthly, yearly }

class RecurringTransactionModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String currency;
  final String category;
  final TransactionType type;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? lastProcessedDate;

  RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    this.currency = 'EUR',
    required this.category,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.lastProcessedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'category': category,
      'type': type.name,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'lastProcessedDate': lastProcessedDate != null ? Timestamp.fromDate(lastProcessedDate!) : null,
    };
  }

  factory RecurringTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringTransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'EUR',
      category: data['category'] ?? '',
      type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      frequency: RecurringFrequency.values.firstWhere((e) => e.name == data['frequency'], orElse: () => RecurringFrequency.monthly),
      startDate: (data['startDate'] as Timestamp).toDate(),
      lastProcessedDate: data['lastProcessedDate'] != null ? (data['lastProcessedDate'] as Timestamp).toDate() : null,
    );
  }
}
