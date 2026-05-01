class BudgetModel {
  final double limit;
  final String period; // 'monthly', 'weekly'

  BudgetModel({required this.limit, this.period = 'monthly'});

  Map<String, dynamic> toMap() {
    return {
      'limit': limit,
      'period': period,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      limit: (map['limit'] ?? 0.0).toDouble(),
      period: map['period'] ?? 'monthly',
    );
  }
}
