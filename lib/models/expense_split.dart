enum SplitType {
  equal,      // Everyone pays the same amount
  percentage, // Split by percentage
  amount,     // Split by specific amounts
  shares      // Split by number of shares
}

class ExpenseSplit {
  final String userId;
  final SplitType splitType;
  final double amount;    // Used for amount splitType
  final double percentage;// Used for percentage splitType
  final int shares;       // Used for shares splitType
  final bool isPaid;
  final DateTime? paidAt;

  ExpenseSplit({
    required this.userId,
    required this.splitType,
    this.amount = 0.0,
    this.percentage = 0.0,
    this.shares = 0,
    this.isPaid = false,
    this.paidAt,
  });

  // Convert ExpenseSplit to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'splitType': splitType.toString().split('.').last,
      'amount': amount,
      'percentage': percentage,
      'shares': shares,
      'isPaid': isPaid,
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  // Create ExpenseSplit from JSON
  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    return ExpenseSplit(
      userId: json['userId'],
      splitType: SplitType.values.firstWhere(
        (e) => e.toString().split('.').last == json['splitType'],
        orElse: () => SplitType.equal,
      ),
      amount: json['amount'] ?? 0.0,
      percentage: json['percentage'] ?? 0.0,
      shares: json['shares'] ?? 0,
      isPaid: json['isPaid'] ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }
} 