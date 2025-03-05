class ProjectStatistics {
  final Map<String, double> categoryTotals;
  final Map<String, double> paymentModeTotals;
  final Map<String, double> memberTotals;
  final double totalAmount;
  final int expenseCount;
  final DateTime? firstExpenseDate;
  final DateTime? lastExpenseDate;
  final Map<String, int> categoryCount;
  final Map<String, int> paymentModeCount;
  final Map<String, int> memberCount;

  ProjectStatistics({
    required this.categoryTotals,
    required this.paymentModeTotals,
    required this.memberTotals,
    required this.totalAmount,
    required this.expenseCount,
    this.firstExpenseDate,
    this.lastExpenseDate,
    required this.categoryCount,
    required this.paymentModeCount,
    required this.memberCount,
  });

  factory ProjectStatistics.fromJson(Map<String, dynamic> json) {
    return ProjectStatistics(
      categoryTotals: Map<String, double>.from(json['categoryTotals'] as Map),
      paymentModeTotals: Map<String, double>.from(json['paymentModeTotals'] as Map),
      memberTotals: Map<String, double>.from(json['memberTotals'] as Map),
      totalAmount: json['totalAmount'] as double,
      expenseCount: json['expenseCount'] as int,
      firstExpenseDate: json['firstExpenseDate'] != null 
        ? DateTime.parse(json['firstExpenseDate'] as String)
        : null,
      lastExpenseDate: json['lastExpenseDate'] != null
        ? DateTime.parse(json['lastExpenseDate'] as String)
        : null,
      categoryCount: Map<String, int>.from(json['categoryCount'] as Map),
      paymentModeCount: Map<String, int>.from(json['paymentModeCount'] as Map),
      memberCount: Map<String, int>.from(json['memberCount'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryTotals': categoryTotals,
      'paymentModeTotals': paymentModeTotals,
      'memberTotals': memberTotals,
      'totalAmount': totalAmount,
      'expenseCount': expenseCount,
      'firstExpenseDate': firstExpenseDate?.toIso8601String(),
      'lastExpenseDate': lastExpenseDate?.toIso8601String(),
      'categoryCount': categoryCount,
      'paymentModeCount': paymentModeCount,
      'memberCount': memberCount,
    };
  }

  // Helper method to get category percentage
  double getCategoryPercentage(String categoryId) {
    return totalAmount > 0 
      ? (categoryTotals[categoryId] ?? 0) / totalAmount * 100 
      : 0;
  }

  // Helper method to get payment mode percentage
  double getPaymentModePercentage(String paymentModeId) {
    return totalAmount > 0 
      ? (paymentModeTotals[paymentModeId] ?? 0) / totalAmount * 100 
      : 0;
  }

  // Helper method to get member percentage
  double getMemberPercentage(String memberId) {
    return totalAmount > 0 
      ? (memberTotals[memberId] ?? 0) / totalAmount * 100 
      : 0;
  }
} 