import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../services/cospend_api_service.dart';
import '../widgets/widgets.dart';
import '../providers/user_provider.dart';
import '../providers/project_provider.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? currentUserId;

  const HomeScreen({super.key, this.currentUserId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Expense> _expenses = [];
  List<Settlement> _settlements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen - initState');
    // Use Future.microtask to schedule the initialization after the current build phase
    Future.microtask(() async {
      final userProvider = context.read<UserProvider>();
      if (userProvider.currentUser == null) {
        await userProvider.loadCurrentUser();
      }
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    debugPrint('HomeScreen - Initializing screen');
    if (!mounted) return;

    final projectProvider = context.read<ProjectProvider>();
    final userProvider = context.read<UserProvider>();
    
    if (userProvider.currentUser == null) {
      setState(() {
        _error = 'User not found. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      await projectProvider.loadProjects();
      if (projectProvider.selectedProject != null) {
        await _loadExpenses();
      }
    } catch (e) {
      debugPrint('HomeScreen - Error initializing screen: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String? _getCurrentUserId() {
    return widget.currentUserId ?? context.read<UserProvider>().currentUser?.id;
  }

  Future<void> _onProjectSelected(Project project) async {
    debugPrint('HomeScreen - Project selected: ${project.name}');
    if (!mounted) return;

    final projectProvider = context.read<ProjectProvider>();
    await projectProvider.setSelectedProject(project.id);
    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selectedProject = context.read<ProjectProvider>().selectedProject;
      final userId = context.read<UserProvider>().currentUser?.id;

      if (selectedProject == null || userId == null) {
        setState(() {
          _expenses = [];
          _settlements = [];
          _isLoading = false;
        });
        return;
      }

      debugPrint('Loading project info for project: ${selectedProject.id}');
      
      // Load expenses first
      final expenses = await CospendApiService.getProjectBills(selectedProject.id);
      
      // Try to load settlements, but use empty list if it fails
      List<Settlement> settlements = [];
      try {
        settlements = await CospendApiService.getProjectSettlements(selectedProject.id);
      } catch (e) {
        debugPrint('Warning: Failed to load settlements: $e');
        // Continue with empty settlements list
      }

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _settlements = settlements;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading project info: $e');
      if (!mounted) return;

      setState(() {
        _expenses = [];
        _settlements = [];
        _isLoading = false;
        _error = 'Failed to load project info. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error ?? 'An error occurred'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadExpenses,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CospendWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance),
            onPressed: () {
              final projectProvider = context.read<ProjectProvider>();
              if (projectProvider.selectedProject != null) {
                debugPrint('HomeScreen - Navigating to settle-up screen');
                Navigator.pushNamed(
                  context,
                  '/settle-up',
                  arguments: {
                    'projectId': projectProvider.selectedProject!.id,
                    'currentUserId': widget.currentUserId ?? context.read<UserProvider>().currentUser?.id ?? '',
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a project first')),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                debugPrint('HomeScreen - Navigating to user-info screen');
                Navigator.pushNamed(context, '/user-info');
              },
              child: UserAvatar(
                user: user,
                radius: 18,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: context.watch<ProjectProvider>().selectedProject != null ? FloatingActionButton(
        onPressed: () {
          debugPrint('HomeScreen - Navigating to add expense screen');
          Navigator.pushNamed(context, '/add-expense');
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildBody() {
    final projectProvider = context.watch<ProjectProvider>();
    
    if (projectProvider.isLoading || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (projectProvider.error != null || _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                projectProvider.error ?? _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeScreen,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (projectProvider.projects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No projects found. Create a new project to get started.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final userId = _getCurrentUserId();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: DropdownButton<Project>(
                  value: projectProvider.selectedProject,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: const Text('Select a project'),
                  items: projectProvider.projects.map((project) {
                    return DropdownMenuItem(
                      value: project,
                      child: Text(
                        project.name,
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  }).toList(),
                  onChanged: (project) {
                    if (project != null) {
                      _onProjectSelected(project);
                    }
                  },
                ),
              ),
            ),
          ),
          if (projectProvider.selectedProject != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: BalanceCard(
                project: projectProvider.selectedProject!,
                expenses: _expenses,
                settlements: _settlements,
                userId: userId ?? '',
              ),
            ),
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(
                      child: Text(
                        'No expenses found in this project.\nAdd an expense to get started!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];
                        return ExpenseCard(
                          expense: expense,
                          onTap: () {
                            debugPrint('HomeScreen - Navigating to expense details: ${expense.id}');
                            Navigator.pushNamed(
                              context,
                              '/expense-details',
                              arguments: expense.id,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
} 