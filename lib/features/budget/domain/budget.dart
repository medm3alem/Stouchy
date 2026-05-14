class BudgetModel {
  final double limit;
  final String currency;
  final String period; // 'monthly', 'weekly'

  BudgetModel({
    required this.limit, 
    this.currency = 'EUR',
    this.period = 'monthly'
  });

  Map<String, dynamic> toMap() {
    return {
      'limit': limit,
      'currency': currency,
      'period': period,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      limit: (map['limit'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'EUR',
      period: map['period'] ?? 'monthly',
    );
  }
}
