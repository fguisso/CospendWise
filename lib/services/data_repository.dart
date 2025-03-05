import '../models/models.dart';
import 'mock_data_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

// This repository would typically connect to a backend or local database.
// For this example, we're using mock data.
class DataRepository {
  final MockDataService _mockDataService = MockDataService();
  final Uuid _uuid = Uuid();
  
  // In-memory cache
  late List<User> _users;
  late List<Project> _projects;
  late List<Expense> _expenses;
  late List<Settlement> _settlements;
  
  // Singleton pattern
  static final DataRepository _instance = DataRepository._internal();
  
  factory DataRepository() {
    debugPrint('DataRepository - Getting instance');
    return _instance;
  }
  
  DataRepository._internal() {
    try {
      debugPrint('DataRepository - Initializing repository');
      // Initialize with mock data
      _users = _mockDataService.getUsers();
      _projects = _mockDataService.getProjects();
      _expenses = _mockDataService.getExpenses();
      _settlements = _mockDataService.getSettlements();
      
      debugPrint('DataRepository - Initialized with:');
      debugPrint('- ${_users.length} users');
      debugPrint('- ${_projects.length} projects');
      debugPrint('- ${_expenses.length} expenses');
      debugPrint('- ${_settlements.length} settlements');
      
      // Verify data integrity
      _verifyDataIntegrity();
    } catch (e, stackTrace) {
      debugPrint('DataRepository - Error initializing repository: $e');
      debugPrint('Stack trace: $stackTrace');
      // Initialize with empty lists to prevent null errors
      _users = [];
      _projects = [];
      _expenses = [];
      _settlements = [];
    }
  }

  // Verify data integrity
  void _verifyDataIntegrity() {
    debugPrint('DataRepository - Verifying data integrity');
    
    // Check projects
    for (var project in _projects) {
      debugPrint('DataRepository - Checking project: ${project.id}');
      debugPrint('- Name: ${project.name}');
      debugPrint('- Description: ${project.description}');
      debugPrint('- Members: ${project.memberIds.length}');
      
      // Verify all member IDs exist
      for (var memberId in project.memberIds) {
        final memberExists = _users.any((user) => user.id == memberId);
        if (!memberExists) {
          debugPrint('WARNING: Project ${project.id} has invalid member ID: $memberId');
        } else {
          final member = _users.firstWhere((user) => user.id == memberId);
          debugPrint('  - Member: ${member.name} (${member.id})');
        }
      }
    }

    // Check expenses
    for (var expense in _expenses) {
      debugPrint('DataRepository - Checking expense: ${expense.id}');
      debugPrint('- Title: ${expense.title}');
      debugPrint('- Amount: ${expense.amount}');
      debugPrint('- Project: ${expense.projectId}');
      debugPrint('- Paid by: ${expense.paidById}');
      
      // Verify project exists
      final projectExists = _projects.any((project) => project.id == expense.projectId);
      if (!projectExists) {
        debugPrint('WARNING: Expense ${expense.id} has invalid project ID: ${expense.projectId}');
      }
      
      // Verify paid by user exists
      final payerExists = _users.any((user) => user.id == expense.paidById);
      if (!payerExists) {
        debugPrint('WARNING: Expense ${expense.id} has invalid paidById: ${expense.paidById}');
      }
    }
  }
  
  // User methods
  List<User> getAllUsers() {
    return List.unmodifiable(_users);
  }
  
  User? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      debugPrint('User not found with ID: $id');
      return null;
    }
  }
  
  User addUser(String name, String email, String? profilePicture) {
    final user = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      profilePicture: profilePicture,
      createdAt: DateTime.now(),
    );
    
    _users.add(user);
    return user;
  }
  
  // Project methods
  List<Project> getProjects() {
    debugPrint('DataRepository - Getting all projects');
    for (var project in _projects) {
      debugPrint('- Project: ${project.name} (${project.id})');
      debugPrint('  Description: ${project.description}');
      debugPrint('  Members: ${project.memberIds.length}');
      debugPrint('  Created: ${project.createdAt}');
      debugPrint('  Updated: ${project.updatedAt}');
    }
    return List.unmodifiable(_projects);
  }
  
  List<Project> getProjectsForUser(String userId) {
    debugPrint('DataRepository - Getting projects for user: $userId');
    final userProjects = _projects.where((project) => project.memberIds.contains(userId)).toList();
    debugPrint('Found ${userProjects.length} projects for user $userId:');
    for (var project in userProjects) {
      debugPrint('- Project: ${project.name} (${project.id})');
      debugPrint('  Description: ${project.description}');
      debugPrint('  Total members: ${project.memberIds.length}');
      debugPrint('  Member IDs: ${project.memberIds.join(', ')}');
      debugPrint('  Created: ${project.createdAt}');
      debugPrint('  Updated: ${project.updatedAt}');
    }
    return List.unmodifiable(userProjects);
  }
  
  Project? getProjectById(String id) {
    debugPrint('DataRepository - Getting project by ID: $id');
    try {
      final project = _projects.firstWhere((project) => project.id == id);
      debugPrint('Found project:');
      debugPrint('- Name: ${project.name}');
      debugPrint('- Description: ${project.description}');
      debugPrint('- Total members: ${project.memberIds.length}');
      debugPrint('- Member IDs: ${project.memberIds.join(', ')}');
      debugPrint('- Created: ${project.createdAt}');
      debugPrint('- Updated: ${project.updatedAt}');
      
      // Log member details
      debugPrint('Member details:');
      for (var memberId in project.memberIds) {
        final member = _users.firstWhere(
          (user) => user.id == memberId,
          orElse: () => User(id: memberId, name: 'Unknown User', email: ''),
        );
        debugPrint('  - ${member.name} (${member.id})');
      }
      
      return project;
    } catch (e) {
      debugPrint('Project not found with ID: $id');
      debugPrint('Error: $e');
      return null;
    }
  }
  
  Future<void> addProject(Project project) async {
    debugPrint('DataRepository - Adding new project:');
    debugPrint('- ID: ${project.id}');
    debugPrint('- Name: ${project.name}');
    debugPrint('- Description: ${project.description}');
    debugPrint('- Members: ${project.memberIds.length}');
    debugPrint('- Member IDs: ${project.memberIds.join(', ')}');
    debugPrint('- Created: ${project.createdAt}');
    debugPrint('- Updated: ${project.updatedAt}');
    
    // Verify member IDs
    for (var memberId in project.memberIds) {
      final memberExists = _users.any((user) => user.id == memberId);
      if (!memberExists) {
        debugPrint('WARNING: Adding project with invalid member ID: $memberId');
      }
    }
    
    _projects.add(project);
    debugPrint('Project added successfully');
  }
  
  Future<void> updateProject(Project project) async {
    debugPrint('DataRepository - Updating project ${project.id}:');
    debugPrint('- Name: ${project.name}');
    debugPrint('- Description: ${project.description}');
    debugPrint('- Members: ${project.memberIds.length}');
    debugPrint('- Member IDs: ${project.memberIds.join(', ')}');
    debugPrint('- Updated: ${project.updatedAt}');
    
    final projectIndex = _projects.indexWhere((p) => p.id == project.id);
    if (projectIndex != -1) {
      _projects[projectIndex] = project;
      debugPrint('Project updated successfully');
    } else {
      debugPrint('ERROR: Project not found for update');
      throw Exception('Project not found with ID: ${project.id}');
    }
  }
  
  Future<void> deleteProject(String projectId) async {
    debugPrint('DataRepository - Deleting project: $projectId');
    
    // Log project details before deletion
    final project = getProjectById(projectId);
    if (project != null) {
      debugPrint('Deleting project details:');
      debugPrint('- Name: ${project.name}');
      debugPrint('- Description: ${project.description}');
      debugPrint('- Members: ${project.memberIds.length}');
    }
    
    final projectExists = _projects.any((p) => p.id == projectId);
    _projects.removeWhere((project) => project.id == projectId);
    
    if (projectExists) {
      debugPrint('Project deleted successfully');
      
      // Clean up related data
      _expenses.removeWhere((expense) => expense.projectId == projectId);
      debugPrint('Removed associated expenses');
      
      _settlements.removeWhere((settlement) => settlement.projectId == projectId);
      debugPrint('Removed associated settlements');
    } else {
      debugPrint('WARNING: Project not found for deletion');
    }
  }
  
  // Expense methods
  List<Expense> getExpensesForProject(String projectId) {
    final expenses = _expenses.where((expense) => expense.projectId == projectId).toList();
    debugPrint('Found ${expenses.length} expenses for project $projectId');
    return List.unmodifiable(expenses);
  }
  
  List<Expense> getExpensesForUser(String userId) {
    final expenses = _expenses.where((expense) => 
      expense.paidById == userId || 
      expense.splits.any((split) => split.userId == userId)
    ).toList();
    debugPrint('Found ${expenses.length} expenses for user $userId');
    return List.unmodifiable(expenses);
  }
  
  Expense? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((expense) => expense.id == id);
    } catch (e) {
      debugPrint('Expense not found with ID: $id');
      return null;
    }
  }
  
  Future<void> addExpense(Expense expense) async {
    debugPrint('Adding new expense:');
    debugPrint('- ID: ${expense.id}');
    debugPrint('- Project ID: ${expense.projectId}');
    debugPrint('- Amount: ${expense.amount}');
    debugPrint('- Paid by: ${expense.paidById}');
    _expenses.add(expense);
  }
  
  // Settlement methods
  List<Settlement> getSettlementsForProject(String projectId) {
    final settlements = _settlements.where((settlement) => settlement.projectId == projectId).toList();
    debugPrint('Found ${settlements.length} settlements for project $projectId');
    return List.unmodifiable(settlements);
  }
  
  List<Settlement> getSettlementsForUser(String userId) {
    final settlements = _settlements.where((settlement) => 
      settlement.fromUserId == userId || settlement.toUserId == userId
    ).toList();
    debugPrint('Found ${settlements.length} settlements for user $userId');
    return List.unmodifiable(settlements);
  }
  
  Settlement? getSettlementById(String id) {
    try {
      return _settlements.firstWhere((settlement) => settlement.id == id);
    } catch (e) {
      debugPrint('Settlement not found with ID: $id');
      return null;
    }
  }
  
  Future<Settlement> createSettlement({
    required String projectId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required DateTime date,
    required SettlementStatus status,
    String? note,
    String? paymentMethod,
    String? transactionReference,
  }) async {
    final settlement = Settlement(
      id: _uuid.v4(),
      projectId: projectId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      date: date,
      status: status,
      note: note,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      createdAt: DateTime.now(),
    );
    
    debugPrint('Creating new settlement:');
    debugPrint('- ID: ${settlement.id}');
    debugPrint('- Project ID: ${settlement.projectId}');
    debugPrint('- From: ${settlement.fromUserId}');
    debugPrint('- To: ${settlement.toUserId}');
    debugPrint('- Amount: ${settlement.amount}');
    
    _settlements.add(settlement);
    return settlement;
  }
  
  Future<bool> updateSettlementStatus(String settlementId, SettlementStatus status) async {
    try {
      final index = _settlements.indexWhere((settlement) => settlement.id == settlementId);
      if (index == -1) {
        debugPrint('Settlement not found with ID: $settlementId');
        return false;
      }
      
      _settlements[index] = Settlement(
        id: _settlements[index].id,
        projectId: _settlements[index].projectId,
        fromUserId: _settlements[index].fromUserId,
        toUserId: _settlements[index].toUserId,
        amount: _settlements[index].amount,
        date: _settlements[index].date,
        status: status,
        note: _settlements[index].note,
        paymentMethod: _settlements[index].paymentMethod,
        transactionReference: _settlements[index].transactionReference,
        createdAt: _settlements[index].createdAt,
      );
      
      debugPrint('Settlement status updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating settlement status: $e');
      return false;
    }
  }
} 