enum SettlementStatus {
  pending,
  completed,
  cancelled
}

class Settlement {
  final String id;
  final String projectId;
  final String fromUserId; // The user who owes money
  final String toUserId;   // The user who is owed money
  final double amount;
  final DateTime date;
  final SettlementStatus status;
  final String? note;
  final String? paymentMethod;
  final String? transactionReference;
  final DateTime? createdAt;

  Settlement({
    required this.id,
    required this.projectId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.date,
    required this.status,
    this.note,
    this.paymentMethod,
    this.transactionReference,
    this.createdAt,
  });

  // Convert Settlement to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'note': note,
      'paymentMethod': paymentMethod,
      'transactionReference': transactionReference,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create Settlement from JSON
  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      amount: json['amount'] as double,
      date: DateTime.parse(json['date'] as String),
      status: SettlementStatus.values.firstWhere(
        (e) => e.toString() == 'SettlementStatus.${json['status']}',
        orElse: () => SettlementStatus.pending,
      ),
      note: json['note'],
      paymentMethod: json['paymentMethod'],
      transactionReference: json['transactionReference'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
} 