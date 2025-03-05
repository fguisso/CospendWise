import '../models/models.dart';
import 'package:flutter/foundation.dart';

class BalanceService {
  static final BalanceService _instance = BalanceService._internal();
  factory BalanceService() => _instance;
  BalanceService._internal();

  /// Round a number to 2 decimal places with proper rounding for currency
  double _round2(double n) {
    // Use banker's rounding (round to nearest even) for better accuracy
    double multiplier = 100.0;
    double value = n.abs() * multiplier;
    int rounded = value.round();
    
    // If exactly halfway between two values, round to the nearest even number
    if ((value - value.floor()) == 0.5) {
      rounded = value.floor() + (value.floor() % 2 == 0 ? 0 : 1);
    }
    
    return (n < 0.0 ? -rounded : rounded) / multiplier;
  }

  /// Normalize a list of amounts to ensure they sum exactly to the target amount
  List<double> _normalizeAmounts(List<double> amounts, double targetAmount) {
    double sum = amounts.fold(0.0, (sum, amount) => sum + amount);
    if ((sum - targetAmount).abs() < 0.01) return amounts;

    // Round each amount to 2 decimal places
    List<double> roundedAmounts = amounts.map((a) => _round2(a)).toList();
    
    // Calculate the difference that needs to be distributed
    double roundedSum = roundedAmounts.fold(0.0, (sum, amount) => sum + amount);
    double diff = targetAmount - roundedSum;
    
    // Distribute the difference cent by cent to the largest amounts
    // This minimizes the relative impact of the adjustment
    if (diff.abs() > 0.001) {
      List<MapEntry<int, double>> indexed = List.generate(
        amounts.length,
        (i) => MapEntry(i, amounts[i]),
      );
      indexed.sort((a, b) => b.value.compareTo(a.value));
      
      int cents = (diff * 100).round();
      int i = 0;
      while (cents != 0) {
        int adjustIndex = indexed[i % amounts.length].key;
        roundedAmounts[adjustIndex] += cents > 0 ? 0.01 : -0.01;
        cents += cents > 0 ? -1 : 1;
        i++;
      }
    }
    
    return roundedAmounts;
  }

  /// Calculate split amounts for an expense
  List<double> _calculateSplitAmounts(Expense expense) {
    List<double> amounts = List.filled(expense.splits.length, 0.0);
    
    switch (expense.splits.first.splitType) {
      case SplitType.equal:
        double equalShare = expense.amount / expense.splits.length;
        amounts = List.filled(expense.splits.length, equalShare);
        break;
        
      case SplitType.percentage:
        amounts = expense.splits.map((split) => 
          expense.amount * (split.percentage / 100)
        ).toList();
        break;
        
      case SplitType.amount:
        amounts = expense.splits.map((split) => split.amount).toList();
        break;
        
      case SplitType.shares:
        int totalShares = expense.splits.fold(0, (sum, split) => sum + split.shares);
        if (totalShares > 0) {
          amounts = expense.splits.map((split) =>
            expense.amount * (split.shares / totalShares)
          ).toList();
        }
        break;
    }
    
    // Normalize amounts to ensure they sum to the expense amount
    return _normalizeAmounts(amounts, expense.amount);
  }

  /// Calculate the overall balance for a user across all groups
  double calculateUserTotalBalance(String userId, List<Expense> expenses, List<Settlement> settlements) {
    double balance = 0.0;
    
    // Calculate from expenses
    for (var expense in expenses) {
      if (expense.splits.isEmpty) continue;
      
      List<double> splitAmounts = _calculateSplitAmounts(expense);
      int userSplitIndex = expense.splits.indexWhere((split) => split.userId == userId);
      
      // If user is the payer
      if (expense.paidById == userId) {
        balance += expense.amount; // Add full amount paid
        if (userSplitIndex >= 0) {
          balance -= splitAmounts[userSplitIndex]; // Subtract user's share
        }
      }
      // If user is included in splits but didn't pay
      else if (userSplitIndex >= 0) {
        balance -= splitAmounts[userSplitIndex];
      }
    }
    
    // Adjust for settlements
    for (var settlement in settlements) {
      if (settlement.status != SettlementStatus.completed) continue;
      
      if (settlement.toUserId == userId) {
        balance -= settlement.amount; // Received money
      }
      if (settlement.fromUserId == userId) {
        balance += settlement.amount; // Paid money
      }
    }
    
    return _round2(balance);
  }
  
  /// Calculate balances for all members in a project
  Map<String, Map<String, double>> _calculateBalances(List<Expense> bills) {
    final Map<String, double> balances = {};     // Net balance for each user (positive = owed, negative = owes)
    final Map<String, double> membersPaid = {};   // Total amount paid by each member
    final Map<String, double> membersSpent = {};  // Total amount spent by each member

    // Initialize maps for all members involved in any bill
    for (var bill in bills) {
      // Initialize for payer if not already done
      if (!balances.containsKey(bill.paidById)) {
        balances[bill.paidById] = 0.0;
        membersPaid[bill.paidById] = 0.0;
        membersSpent[bill.paidById] = 0.0;
      }

      // Initialize for all members in splits
      for (var split in bill.splits) {
        if (!balances.containsKey(split.userId)) {
          balances[split.userId] = 0.0;
          membersPaid[split.userId] = 0.0;
          membersSpent[split.userId] = 0.0;
        }
      }
    }

    // Process each bill
    for (var bill in bills) {
      // Add the full amount to what the payer paid
      membersPaid[bill.paidById] = (membersPaid[bill.paidById] ?? 0.0) + bill.amount;
      
      // Check if the bill has splits
      if (bill.splits.isEmpty) {
        // Edge case: If no splits, the person who paid also spent it all
        membersSpent[bill.paidById] = (membersSpent[bill.paidById] ?? 0.0) + bill.amount;
        continue;
      }

      // For bills with splits, calculate each user's share of the expense
      double totalCalculatedAmount = 0.0;
      
      // First pass - calculate amounts without normalization
      Map<String, double> tempSpentAmounts = {};
      
      for (var split in bill.splits) {
        double spentAmount = 0.0;
        
        if (split.splitType == SplitType.equal) {
          spentAmount = bill.amount / bill.splits.length;
        } else if (split.splitType == SplitType.percentage) {
          spentAmount = bill.amount * (split.percentage / 100);
        } else if (split.splitType == SplitType.amount) {
          spentAmount = split.amount;
        } else if (split.splitType == SplitType.shares) {
          int totalShares = bill.splits.fold(0, (sum, s) => sum + s.shares);
          // Guard against division by zero
          if (totalShares > 0) {
            spentAmount = bill.amount * (split.shares / totalShares);
          }
        }
        
        tempSpentAmounts[split.userId] = spentAmount;
        totalCalculatedAmount += spentAmount;
      }
      
      // Normalize the spent amounts if needed (to handle rounding errors)
      if (totalCalculatedAmount > 0 && (totalCalculatedAmount - bill.amount).abs() > 0.01) {
        double factor = bill.amount / totalCalculatedAmount;
        tempSpentAmounts.forEach((userId, amount) {
          tempSpentAmounts[userId] = amount * factor;
        });
      }
      
      // Add the normalized spent amounts to the total
      tempSpentAmounts.forEach((userId, amount) {
        membersSpent[userId] = (membersSpent[userId] ?? 0.0) + amount;
      });
    }

    // Calculate final balances
    membersPaid.forEach((userId, paid) {
      final spent = membersSpent[userId] ?? 0.0;
      balances[userId] = paid - spent;
    });

    // Round all values to 2 decimal places
    balances.updateAll((key, value) => _round2(value));
    membersPaid.updateAll((key, value) => _round2(value));
    membersSpent.updateAll((key, value) => _round2(value));

    if (kDebugMode) {
      debugPrint('\nBalance calculation results:');
      final sortedUserIds = balances.keys.toList()..sort();
      for (final userId in sortedUserIds) {
        final paid = membersPaid[userId] ?? 0.0;
        final spent = membersSpent[userId] ?? 0.0;
        final balance = balances[userId] ?? 0.0;
        final owed = balance > 0 ? balance : 0.0;
        final owing = balance < 0 ? -balance : 0.0;
        debugPrint('User $userId:');
        debugPrint('  Paid: ${paid.toStringAsFixed(2)}');
        debugPrint('  Spent: ${spent.toStringAsFixed(2)}');
        debugPrint('  Owing: ${owing.toStringAsFixed(2)}');
        debugPrint('  Owed: ${owed.toStringAsFixed(2)}\n');
      }
    }

    return {
      'balances': balances,
      'paid': membersPaid,
      'spent': membersSpent,
    };
  }

  /// Calculate the net balance for a specific user in a project
  Map<String, double> calculateUserProjectBalance(
    String userId,
    String projectId,
    List<Expense> expenses,
    List<Settlement> settlements,
  ) {
    final results = _calculateBalances(expenses);
    double balance = results['balances']?[userId] ?? 0.0;
    final paid = results['paid']?[userId] ?? 0.0;
    final spent = results['spent']?[userId] ?? 0.0;
    
    // Adjust for settlements
    for (final settlement in settlements) {
      if (settlement.fromUserId == userId) {
        // User paid money to someone else
        balance -= settlement.amount;
      }
      if (settlement.toUserId == userId) {
        // User received money from someone else
        balance += settlement.amount;
      }
    }
    
    final finalBalance = _round2(balance);
    return {
      'balance': finalBalance,
      'paid': paid,
      'spent': spent,
      'owed': finalBalance > 0 ? finalBalance : 0.0,
      'owing': finalBalance < 0 ? -finalBalance : 0.0,
    };
  }
  
  // Get a map of how much each member in a project owes or is owed
  Map<String, double> getProjectBalances(String projectId, List<String> memberIds, List<Expense> expenses, List<Settlement> settlements) {
    Map<String, double> balances = {};
    
    for (var memberId in memberIds) {
      balances[memberId] = calculateUserProjectBalance(memberId, projectId, expenses, settlements)['balance'] ?? 0.0;
    }
    
    return balances;
  }
  
  // Calculate simplified debt relations (who should pay whom to minimize transactions)
  List<Map<String, dynamic>> calculateOptimalSettlements(String projectId, List<String> memberIds, List<Expense> expenses, List<Settlement> settlements) {
    var balances = getProjectBalances(projectId, memberIds, expenses, settlements);
    List<Map<String, dynamic>> optimalSettlements = [];
    
    // Separate debtors (negative balance) and creditors (positive balance)
    var debtors = balances.entries.where((entry) => entry.value < 0).toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Sort by amount (most negative first)
    
    var creditors = balances.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by amount (most positive first)
      
    // Match debtors with creditors until all debts are settled
    int debtorIndex = 0;
    int creditorIndex = 0;
    
    while (debtorIndex < debtors.length && creditorIndex < creditors.length) {
      String debtorId = debtors[debtorIndex].key;
      String creditorId = creditors[creditorIndex].key;
      double debtorAmount = -debtors[debtorIndex].value; // Make it positive for easier calculation
      double creditorAmount = creditors[creditorIndex].value;
      
      double settlementAmount = debtorAmount < creditorAmount ? debtorAmount : creditorAmount;
      
      optimalSettlements.add({
        'fromUserId': debtorId,
        'toUserId': creditorId,
        'amount': settlementAmount,
      });
      
      // Update balances and move to next person if their balance is settled
      if (debtorAmount - settlementAmount < 0.01) { // Use a small epsilon for float comparison
        debtorIndex++;
      } else {
        debtors[debtorIndex] = MapEntry(debtorId, -(debtorAmount - settlementAmount));
      }
      
      if (creditorAmount - settlementAmount < 0.01) { // Use a small epsilon for float comparison
        creditorIndex++;
      } else {
        creditors[creditorIndex] = MapEntry(creditorId, creditorAmount - settlementAmount);
      }
    }
    
    return optimalSettlements;
  }
} 