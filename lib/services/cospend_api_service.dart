import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'cospend_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CospendApiService {
  static Future<Map<String, String>> _getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'url': prefs.getString('cospend_url') ?? '',
      'username': prefs.getString('cospend_username') ?? '',
      'password': prefs.getString('cospend_password') ?? '',
    };
  }

  /// Get all projects for the current user
  static Future<List<Project>> getProjects() async {
    try {
      final credentials = await _getCredentials();
      
      // First try the new OCS API (version > 1.6.1)
      try {
        debugPrint('CospendApiService - Trying new OCS API endpoint');
        final response = await CospendService.makeAuthenticatedRequest(
          url: credentials['url']!,
          username: credentials['username']!,
          password: credentials['password']!,
          endpoint: 'ocs/v2.php/apps/cospend/api/v1/projects',
          useOcsApi: true,
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          final List<dynamic> projectsJson = jsonResponse['ocs']['data'];
          return projectsJson.map((json) => _convertJsonToProject(json)).toList();
        }
      } catch (e) {
        debugPrint('CospendApiService - New API failed: $e');
      }

      // If new API fails, try the legacy private API
      try {
        debugPrint('CospendApiService - Trying legacy private API endpoint');
        final response = await CospendService.makeAuthenticatedRequest(
          url: credentials['url']!,
          username: credentials['username']!,
          password: credentials['password']!,
          endpoint: 'index.php/apps/cospend/api-priv/projects',
          useOcsApi: false,
        );

        if (response.statusCode == 200) {
          final List<dynamic> projectsJson = jsonDecode(response.body);
          return projectsJson.map((json) => _convertLegacyJsonToProject(json)).toList();
        }
      } catch (e) {
        debugPrint('CospendApiService - Legacy API failed: $e');
      }

      throw Exception('Failed to load projects from both new and legacy APIs');
    } catch (e) {
      debugPrint('CospendApiService - Error getting projects: $e');
      rethrow;
    }
  }

  /// Get all members of a project
  static Future<List<User>> getProjectMembers(String projectId) async {
    try {
      final credentials = await _getCredentials();
      final response = await CospendService.makeAuthenticatedRequest(
        url: credentials['url']!,
        username: credentials['username']!,
        password: credentials['password']!,
        endpoint: 'ocs/v2.php/apps/cospend/api/v1/projects/$projectId/members',
        useOcsApi: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> membersJson = jsonResponse['ocs']['data'];
        return membersJson.map((json) => _convertMemberToUser(json)).toList();
      }
      throw Exception('Failed to load project members');
    } catch (e) {
      rethrow;
    }
  }

  /// Get all bills (expenses) for a project
  static Future<List<Expense>> getProjectBills(String projectId) async {
    try {
      final credentials = await _getCredentials();
      
      // First try the new OCS API (version > 1.6.1)
      try {
        debugPrint('CospendApiService - Trying new OCS API endpoint for bills');
        final response = await CospendService.makeAuthenticatedRequest(
          url: credentials['url']!,
          username: credentials['username']!,
          password: credentials['password']!,
          endpoint: 'ocs/v2.php/apps/cospend/api/v1/projects/$projectId/bills',
          useOcsApi: true,
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          final List<dynamic> billsJson = jsonResponse['ocs']['data']['bills'] as List<dynamic>;
          debugPrint('CospendApiService - Found ${billsJson.length} bills using new API');
          return billsJson.map((json) => _convertBillToExpense(json, projectId)).toList();
        }
      } catch (e) {
        debugPrint('CospendApiService - New API failed for bills: $e');
      }

      // If new API fails, try the legacy private API
      try {
        debugPrint('CospendApiService - Trying legacy private API endpoint for bills');
        final response = await CospendService.makeAuthenticatedRequest(
          url: credentials['url']!,
          username: credentials['username']!,
          password: credentials['password']!,
          endpoint: 'index.php/apps/cospend/api-priv/projects/$projectId/bills',
          useOcsApi: false,
        );

        if (response.statusCode == 200) {
          debugPrint('CospendApiService - Legacy API response received');
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
          final List<dynamic> billsJson = jsonResponse['bills'] as List<dynamic>;
          debugPrint('CospendApiService - Found ${billsJson.length} bills using legacy API');
          return billsJson.map((json) => _convertLegacyBillToExpense(json, projectId)).toList();
        }
      } catch (e) {
        debugPrint('CospendApiService - Legacy API failed for bills: $e');
      }

      throw Exception('Failed to load bills from both new and legacy APIs');
    } catch (e) {
      debugPrint('CospendApiService - Error getting bills: $e');
      rethrow;
    }
  }

  /// Create a new bill (expense)
  static Future<Expense> createBill({
    required String projectId,
    required String what,
    required double amount,
    required String paidById,
    required List<ExpenseSplit> splits,
    String? comment,
    DateTime? date,
  }) async {
    try {
      final credentials = await _getCredentials();
      final Map<String, dynamic> body = {
        'what': what,
        'amount': amount,
        'payer': paidById,
        'date': (date ?? DateTime.now()).toIso8601String(),
        'comment': comment ?? '',
        'splits': splits.map((split) => {
          'member_id': split.userId,
          'weight': split.splitType == SplitType.shares ? split.shares : 1,
          'amount': split.splitType == SplitType.amount ? split.amount : null,
        }).toList(),
      };

      final response = await CospendService.makeAuthenticatedRequest(
        url: credentials['url']!,
        username: credentials['username']!,
        password: credentials['password']!,
        endpoint: 'ocs/v2.php/apps/cospend/api/v1/projects/$projectId/bills',
        method: 'POST',
        body: body,
        useOcsApi: true,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final billJson = jsonResponse['ocs']['data'];
        return _convertBillToExpense(billJson, projectId);
      }
      throw Exception('Failed to create bill');
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new settlement
  static Future<Settlement> createSettlement({
    required String projectId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? comment,
  }) async {
    try {
      final credentials = await _getCredentials();
      final Map<String, dynamic> body = {
        'from': fromUserId,
        'to': toUserId,
        'amount': amount,
        'comment': comment ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await CospendService.makeAuthenticatedRequest(
        url: credentials['url']!,
        username: credentials['username']!,
        password: credentials['password']!,
        endpoint: 'projects/$projectId/settlements',
        method: 'POST',
        body: body,
      );

      if (response.statusCode == 201) {
        final settlementJson = jsonDecode(response.body);
        return _convertSettlementToSettlement(settlementJson, projectId);
      }
      throw Exception('Failed to create settlement');
    } catch (e) {
      rethrow;
    }
  }

  /// Get the current user's information
  static Future<User> getCurrentUser() async {
    debugPrint('CospendApiService - Getting current user info');
    
    try {
      final credentials = await _getCredentials();
      
      // First try to get user info from Nextcloud endpoint
      try {
        debugPrint('CospendApiService - Trying Nextcloud user endpoint');
        final response = await CospendService.makeAuthenticatedRequest(
          url: credentials['url']!,
          username: credentials['username']!,
          password: credentials['password']!,
          endpoint: 'ocs/v2.php/cloud/user',
          useOcsApi: true,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userInfo = data['ocs']['data'];
          
          // Construct the avatar URL
          final baseUrl = credentials['url']!;
          final avatarUrl = '$baseUrl/index.php/avatar/${credentials['username']!}/64';
          
          debugPrint('CospendApiService - User info retrieved successfully');
          debugPrint('- Username: ${userInfo['displayname']}');
          debugPrint('- Email: ${userInfo['email']}');
          debugPrint('- Avatar URL: $avatarUrl');
          
          return User(
            id: credentials['username']!,
            name: userInfo['displayname'] ?? credentials['username']!,
            email: userInfo['email'] ?? '${credentials['username']}@${Uri.parse(credentials['url']!).host}',
            profilePicture: avatarUrl,
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        debugPrint('CospendApiService - Error getting user info from Nextcloud: $e');
      }
      
      // Fallback to basic user info if Nextcloud endpoint fails
      debugPrint('CospendApiService - Using basic user info');
      return User(
        id: credentials['username']!,
        name: credentials['username']!,
        email: '${credentials['username']}@${Uri.parse(credentials['url']!).host}',
        profilePicture: '${credentials['url']!}/index.php/avatar/${credentials['username']!}/64',
        createdAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('CospendApiService - Error getting current user: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to load user info: $e');
    }
  }

  /// Get project information including balances
  static Future<Map<String, dynamic>> getProjectInfo(String projectId) async {
    debugPrint('CospendApiService - Getting project info for: $projectId');
    
    try {
      final credentials = await _getCredentials();
      
      // First try the new OCS API
      try {
        debugPrint('CospendApiService - Trying new OCS API for project info');
        final response = await CospendService.makeAuthenticatedRequest(
          url: credentials['url']!,
          username: credentials['username']!,
          password: credentials['password']!,
          endpoint: 'ocs/v2.php/apps/cospend/api/v1/projects/$projectId',
          useOcsApi: true,
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final projectData = jsonResponse['ocs']['data'];
          
          // Get project bills to calculate balances
          final bills = await getProjectBills(projectId);
          final balances = _calculateBalances(bills);
          
          return {
            'project': projectData,
            'bills': bills,
            'balances': balances,
          };
        }
      } catch (e) {
        debugPrint('CospendApiService - New API failed: $e');
      }

      // Try legacy API if new API fails
      debugPrint('CospendApiService - Trying legacy API for project info');
      final response = await CospendService.makeAuthenticatedRequest(
        url: credentials['url']!,
        username: credentials['username']!,
        password: credentials['password']!,
        endpoint: 'index.php/apps/cospend/api-priv/projects/$projectId',
        useOcsApi: false,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Get project bills to calculate balances
        final bills = await getProjectBills(projectId);
        final balances = _calculateBalances(bills);
        
        return {
          'project': jsonResponse,
          'bills': bills,
          'balances': balances,
        };
      }

      throw Exception('Failed to get project info');
    } catch (e) {
      debugPrint('CospendApiService - Error getting project info: $e');
      rethrow;
    }
  }

  /// Calculate balances for all members in a project
  static Map<String, Map<String, double>> _calculateBalances(List<Expense> bills) {
    final Map<String, double> owedBalances = {};  // Positive balances (money owed to user)
    final Map<String, double> owingBalances = {}; // Negative balances (money user owes)
    final Map<String, double> membersPaid = {};   // Total amount paid by each member
    final Map<String, double> membersSpent = {};  // Total amount spent by each member
    final Map<String, int> membersWeight = {};    // Weight/shares of each member

    // Initialize maps for all members involved in any bill
    for (var bill in bills) {
      // Initialize for payer if not already done
      if (!owedBalances.containsKey(bill.paidById)) {
        owedBalances[bill.paidById] = 0.0;
        owingBalances[bill.paidById] = 0.0;
        membersPaid[bill.paidById] = 0.0;
        membersSpent[bill.paidById] = 0.0;
        membersPaid[bill.paidById] = 0.0;
      }

      // Initialize for all members in splits
      for (var split in bill.splits) {
        if (!owedBalances.containsKey(split.userId)) {
          owedBalances[split.userId] = 0.0;
          owingBalances[split.userId] = 0.0;
          membersPaid[split.userId] = 0.0;
          membersSpent[split.userId] = 0.0;
        }
        // Store the member's weight/shares
        membersPaid[split.userId] = split.shares.toDouble();
      }
    }

    // Calculate balances for each bill
    for (var bill in bills) {
      final amount = bill.amount;
      
      // Add the full amount to what others owe the payer
      membersPaid[bill.paidById] = (membersPaid[bill.paidById] ?? 0.0) + amount;
      owedBalances[bill.paidById] = (owedBalances[bill.paidById] ?? 0.0) + amount;

      // Calculate total shares for this bill
      double totalShares = 0.0;
      for (var split in bill.splits) {
        totalShares += split.shares;
      }

      // Calculate what each person owes for this bill
      for (var split in bill.splits) {
        // Calculate the amount this person owes based on their shares
        final double shareAmount = (amount * split.shares) / totalShares;

        // Update spent amount for this member
        membersSpent[split.userId] = (membersSpent[split.userId] ?? 0.0) + shareAmount;

        // If this is not the payer, add to their owing balance
        if (split.userId != bill.paidById) {
          owingBalances[split.userId] = (owingBalances[split.userId] ?? 0.0) + shareAmount;
        }
        
        // Subtract the share from what others owe the payer if this is the payer
        if (split.userId == bill.paidById) {
          owedBalances[bill.paidById] = (owedBalances[bill.paidById] ?? 0.0) - shareAmount;
        }
      }
    }

    // Round all values to 2 decimal places
    owedBalances.updateAll((key, value) => _round2(value));
    owingBalances.updateAll((key, value) => _round2(value));

    debugPrint('\nBalance calculation results:');
    owedBalances.forEach((userId, balance) {
      final owing = owingBalances[userId] ?? 0.0;
      final netBalance = balance - owing;
      debugPrint('User $userId:');
      debugPrint('  Paid: ${membersPaid[userId]?.toStringAsFixed(2)}');
      debugPrint('  Spent: ${membersSpent[userId]?.toStringAsFixed(2)}');
      debugPrint('  Owed: ${balance.toStringAsFixed(2)}');
      debugPrint('  Owing: ${owing.toStringAsFixed(2)}');
      debugPrint('  Net balance: ${netBalance.toStringAsFixed(2)}\n');
    });

    return {
      'owed': owedBalances,    // Positive balances (money owed to user)
      'owing': owingBalances,  // Negative balances (money user owes)
    };
  }

  /// Round a number to 2 decimal places
  static double _round2(double n) {
    double r = (n.abs() * 100.0).round() / 100.0;
    return n < 0.0 ? -r : r;
  }

  // Conversion helpers
  static Project _convertJsonToProject(Map<String, dynamic> json) {
    // Extract member IDs from active_members array
    final List<String> memberIds = (json['active_members'] as List)
        .map((member) => member['userid'].toString())
        .toList();

    // Get project name and ID from the first share
    final List<dynamic> shares = json['shares'] as List;
    if (shares.isEmpty) {
      throw Exception('Invalid project data: no shares found');
    }

    final String projectId = shares[0]['projectid'].toString();
    final String projectName = shares[0]['name'].toString();

    return Project(
      id: projectId,
      name: projectName,
      description: json['description'] as String? ?? '',
      memberIds: memberIds,
      createdAt: DateTime.now(), // Cospend doesn't provide project creation date
      updatedAt: DateTime.now(),
    );
  }

  static Project _convertLegacyJsonToProject(Map<String, dynamic> json) {
    return Project(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unnamed Project',
      description: json['description'] as String? ?? '',
      memberIds: (json['members'] as List? ?? [])
          .map((member) => member['userid'].toString())
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static User _convertMemberToUser(Map<String, dynamic> json) {
    return User(
      id: json['userid'].toString(),
      name: json['name'],
      email: '', // Cospend doesn't provide member emails
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['lastchanged'] as int) * 1000,
      ),
    );
  }

  static Expense _convertBillToExpense(Map<String, dynamic> json, String projectId) {
    try {
      debugPrint('Converting bill to expense: ${json['what']}');
      
      // Parse the amount safely
      double amount;
      try {
        amount = double.parse(json['amount'].toString());
      } catch (e) {
        debugPrint('Error parsing amount: ${json['amount']}');
        amount = 0.0;
      }

      // Parse the date safely
      DateTime date;
      try {
        date = DateTime.parse(json['date']);
      } catch (e) {
        debugPrint('Error parsing date: ${json['date']}');
        date = DateTime.now();
      }

      // Get splits from owers array
      List<ExpenseSplit> splits = [];
      final List<dynamic> owers = json['owers'] ?? [];
      splits = owers.map((ower) {
        return ExpenseSplit(
          userId: ower['id'].toString(),
          splitType: SplitType.shares,
          shares: ower['weight'] ?? 1,
          amount: 0.0,
        );
      }).toList();

      // Add payer to splits if not already included
      final String payerId = json['payer_id'].toString();
      if (!splits.any((split) => split.userId == payerId)) {
        splits.add(ExpenseSplit(
          userId: payerId,
          splitType: SplitType.shares,
          shares: 1,
          amount: 0.0,
        ));
      }

      return Expense(
        id: json['id'].toString(),
        title: json['what'] ?? 'Untitled',
        description: json['description'] ?? '',
        amount: amount,
        paidById: payerId,
        projectId: projectId,
        date: date,
        category: _getCategoryFromPaymentMode(json['paymentmode']),
        splits: splits,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['timestamp'] is int) 
              ? json['timestamp'] * 1000 
              : int.parse(json['timestamp'].toString()) * 1000
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error converting bill to expense: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Original JSON: $json');
      rethrow;
    }
  }

  static Expense _convertLegacyBillToExpense(Map<String, dynamic> json, String projectId) {
    try {
      debugPrint('Converting legacy bill to expense: ${json['what']}');
      
      // Parse the amount safely
      double amount;
      try {
        amount = double.parse(json['amount'].toString());
      } catch (e) {
        debugPrint('Error parsing amount: ${json['amount']}');
        amount = 0.0;
      }

      // Parse the date safely
      DateTime date;
      try {
        date = DateTime.parse(json['date']);
      } catch (e) {
        debugPrint('Error parsing date: ${json['date']}');
        date = DateTime.now();
      }

      // Get splits from owers
      List<ExpenseSplit> splits = [];
      final List<dynamic> owers = json['owers'] ?? [];
      splits = owers.map((ower) {
        return ExpenseSplit(
          userId: ower['id'].toString(),
          splitType: SplitType.shares,
          shares: ower['weight'] ?? 1,
          amount: 0.0,
        );
      }).toList();

      return Expense(
        id: json['id'].toString(),
        title: json['what'] ?? 'Untitled',
        description: json['description'] ?? '',
        amount: amount,
        paidById: json['payer_id'].toString(),
        projectId: projectId,
        date: date,
        category: ExpenseCategory.other,
        splits: splits,
        createdAt: DateTime.fromMillisecondsSinceEpoch((json['timestamp'] as int) * 1000),
      );
    } catch (e, stackTrace) {
      debugPrint('Error converting legacy bill to expense: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Original JSON: $json');
      rethrow;
    }
  }

  static ExpenseCategory _getCategoryFromPaymentMode(dynamic paymentMode) {
    // Handle string payment modes
    if (paymentMode is String) {
      switch (paymentMode.toLowerCase()) {
        case 'n':
          return ExpenseCategory.other;
        case 'a':
          return ExpenseCategory.other; // Advanced payment
        case 'r':
          return ExpenseCategory.other; // Reimbursement
        default:
          return ExpenseCategory.other;
      }
    }
    
    // Handle numeric payment modes
    if (paymentMode is int) {
      switch (paymentMode) {
        case 1:
          return ExpenseCategory.other; // Advanced payment
        case 2:
          return ExpenseCategory.other; // Reimbursement
        default:
          return ExpenseCategory.other; // Simple payment
      }
    }
    
    return ExpenseCategory.other;
  }

  static Settlement _convertSettlementToSettlement(
    Map<String, dynamic> json,
    String projectId,
  ) {
    return Settlement(
      id: json['id'].toString(),
      projectId: projectId,
      fromUserId: json['from'].toString(),
      toUserId: json['to'].toString(),
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['timestamp']),
      status: SettlementStatus.completed,
      note: json['comment'],
      createdAt: DateTime.parse(json['timestamp']),
    );
  }

  /// Get all settlements for a project
  static Future<List<Settlement>> getProjectSettlements(String projectId) async {
    try {
      final credentials = await _getCredentials();
      List<String> endpoints = [
        // Try new OCS API endpoints
        'ocs/v2.php/apps/cospend/api/v1/projects/$projectId/settlements',
        'ocs/v2.php/apps/cospend/api/v2/projects/$projectId/settlements',
        // Try legacy API endpoints
        'index.php/apps/cospend/api/projects/$projectId/settlements',
        'index.php/apps/cospend/api-priv/projects/$projectId/settlements',
      ];

      for (var endpoint in endpoints) {
        try {
          debugPrint('CospendApiService - Trying endpoint: $endpoint');
          final response = await CospendService.makeAuthenticatedRequest(
            url: credentials['url']!,
            username: credentials['username']!,
            password: credentials['password']!,
            endpoint: endpoint,
            useOcsApi: endpoint.startsWith('ocs'),
            retryOnError: true, // Enable retrying on SSL errors
          );

          if (response.statusCode == 200) {
            Map<String, dynamic> jsonResponse;
            List<dynamic> settlementsJson;

            try {
              jsonResponse = jsonDecode(response.body);
              if (endpoint.startsWith('ocs')) {
                settlementsJson = jsonResponse['ocs']['data'] as List<dynamic>;
              } else {
                settlementsJson = (jsonResponse['settlements'] ?? []) as List<dynamic>;
              }

              debugPrint('CospendApiService - Found ${settlementsJson.length} settlements using endpoint: $endpoint');
              return settlementsJson.map((json) => _convertSettlementToSettlement(json, projectId)).toList();
            } catch (e) {
              debugPrint('CospendApiService - Error parsing response from $endpoint: $e');
              continue;
            }
          } else {
            debugPrint('CospendApiService - Endpoint $endpoint returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('CospendApiService - Error with endpoint $endpoint: $e');
          continue;
        }
      }

      // If no settlements are found after trying all endpoints, return an empty list
      debugPrint('CospendApiService - No settlements found after trying all endpoints');
      return [];
    } catch (e) {
      debugPrint('CospendApiService - Error getting settlements: $e');
      rethrow;
    }
  }
} 