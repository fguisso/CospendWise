import 'package:uuid/uuid.dart';
import '../models/models.dart';

class MockDataService {
  final uuid = Uuid();
  
  // Generate a list of mock users
  List<User> getUsers() {
    return [
      User(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
      ),
      User(
        id: 'user2',
        name: 'Jane Smith',
        email: 'jane@example.com',
      ),
      User(
        id: 'user3',
        name: 'Bob Johnson',
        email: 'bob@example.com',
      ),
    ];
  }

  // Generate a list of mock projects
  List<Project> getProjects() {
    return [
      Project(
        id: '1',
        name: 'Summer Vacation',
        description: 'Summer vacation expenses',
        memberIds: ['1', '2', '3'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Project(
        id: '2',
        name: 'Shared Apartment',
        description: 'Shared apartment expenses',
        memberIds: ['1', '2'],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Project(
        id: '3',
        name: 'Team Lunch',
        description: 'Team lunch expenses',
        memberIds: ['1', '2', '3', '4'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  // Generate a list of mock expenses
  List<Expense> getExpenses() {
    return [
      Expense(
        id: 'expense1',
        description: 'Hotel Booking',
        amount: 300.0,
        paidById: 'user1',
        projectId: 'project1',
        date: DateTime.now().subtract(const Duration(days: 5)),
        category: ExpenseCategory.travel,
        splits: [
          ExpenseSplit(userId: 'user1', splitType: SplitType.equal),
          ExpenseSplit(userId: 'user2', splitType: SplitType.equal),
          ExpenseSplit(userId: 'user3', splitType: SplitType.equal),
        ],
      ),
      Expense(
        id: 'expense2',
        description: 'Groceries',
        amount: 150.0,
        paidById: 'user2',
        projectId: 'project2',
        date: DateTime.now().subtract(const Duration(days: 3)),
        category: ExpenseCategory.groceries,
        splits: [
          ExpenseSplit(userId: 'user1', splitType: SplitType.equal),
          ExpenseSplit(userId: 'user2', splitType: SplitType.equal),
        ],
      ),
    ];
  }

  // Generate a list of mock settlements
  List<Settlement> getSettlements() {
    return [
      Settlement(
        id: 'settlement1',
        projectId: 'project1',
        fromUserId: 'user2',
        toUserId: 'user1',
        amount: 100.0,
        date: DateTime.now().subtract(const Duration(days: 2)),
        status: SettlementStatus.completed,
      ),
      Settlement(
        id: 'settlement2',
        projectId: 'project2',
        fromUserId: 'user1',
        toUserId: 'user2',
        amount: 75.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: SettlementStatus.pending,
      ),
    ];
  }
} 