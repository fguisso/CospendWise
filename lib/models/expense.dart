import 'expense_split.dart';

enum ExpenseCategory {
  food,
  transportation,
  utilities,
  rent,
  entertainment,
  shopping,
  travel,
  groceries,
  other,
}

class Expense {
  final String id;
  final String? title;
  final String description;
  final double amount;
  final String paidById; // User ID of the person who paid
  final String projectId;
  final DateTime date;
  final ExpenseCategory category;
  final List<ExpenseSplit> splits; // How the expense is split among members
  final String? receiptImage;
  final DateTime? createdAt;

  Expense({
    required this.id,
    this.title,
    required this.description,
    required this.amount,
    required this.paidById,
    required this.projectId,
    required this.date,
    required this.category,
    required this.splits,
    this.receiptImage,
    this.createdAt,
  });

  // Convert Expense to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'paidById': paidById,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'category': category.toString().split('.').last,
      'splits': splits.map((split) => split.toJson()).toList(),
      'receiptImage': receiptImage,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String,
      amount: json['amount'] as double,
      paidById: json['paidById'] as String,
      projectId: json['projectId'] as String,
      date: DateTime.parse(json['date'] as String),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == 'ExpenseCategory.${json['category']}',
        orElse: () => ExpenseCategory.other,
      ),
      splits: (json['splits'] as List)
          .map((split) => ExpenseSplit.fromJson(split as Map<String, dynamic>))
          .toList(),
      receiptImage: json['receiptImage'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
} 