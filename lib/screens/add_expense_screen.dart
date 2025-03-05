import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? currentUserId;
  final String? projectId;

  const AddExpenseScreen({
    super.key,
    this.currentUserId,
    this.projectId,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  List<Project> _userProjects = [];
  List<String> _projectMembers = [];
  String? _selectedProjectId;
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  SplitType _splitType = SplitType.equal;
  Map<String, double> _splitAmounts = {};
  Map<String, int> _splitShares = {};
  Map<String, double> _splitPercentages = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('Initializing AddExpenseScreen');
    debugPrint('Current user ID: ${widget.currentUserId}');
    debugPrint('Initial project ID: ${widget.projectId}');
    
    _selectedProjectId = widget.projectId;
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      await _loadUserProjects();
    } catch (e, stackTrace) {
      debugPrint('Error initializing screen: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to initialize screen: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing AddExpenseScreen');
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProjects() async {
    if (!mounted) return;
    
    debugPrint('Loading user projects for user: ${widget.currentUserId}');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.currentUserId == null || widget.currentUserId!.isEmpty) {
        throw Exception('Current user ID is required');
      }

      final projects = await context.read<DataRepository>().getProjectsForUser(widget.currentUserId!);
      debugPrint('Loaded ${projects.length} projects');

      if (!mounted) return;

      setState(() {
        _userProjects = projects;
        if (_selectedProjectId == null && projects.isNotEmpty) {
          _selectedProjectId = projects.first.id;
          debugPrint('Selected first project: ${projects.first.name} (${projects.first.id})');
        }
      });

      if (_selectedProjectId != null) {
        debugPrint('Loading members for project: $_selectedProjectId');
        await _loadProjectMembers(_selectedProjectId!);
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading projects: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load projects: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProjectMembers(String projectId) async {
    if (!mounted) return;
    
    debugPrint('Loading members for project: $projectId');
    try {
      final project = await context.read<DataRepository>().getProjectById(projectId);
      if (!mounted) return;

      if (project != null) {
        debugPrint('Project found: ${project.name}');
        debugPrint('Member IDs: ${project.memberIds.join(', ')}');
        setState(() {
          _projectMembers = project.memberIds;
          debugPrint('Loaded ${_projectMembers.length} members');
          _resetSplitValues();
        });
      } else {
        debugPrint('Project not found: $projectId');
        setState(() {
          _error = 'Project not found';
          _projectMembers = [];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading project members: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load project members: $e';
        _projectMembers = [];
      });
    }
  }

  void _resetSplitValues() {
    if (_projectMembers.isEmpty) {
      debugPrint('Warning: No project members to split with');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final memberCount = _projectMembers.length;
    
    debugPrint('Resetting split values:');
    debugPrint('- Amount: $amount');
    debugPrint('- Member count: $memberCount');
    debugPrint('- Split type: $_splitType');
    
    try {
      setState(() {
        _splitAmounts = Map.fromIterable(
          _projectMembers,
          key: (member) => member as String,
          value: (_) => amount / memberCount,
        );
        
        _splitShares = Map.fromIterable(
          _projectMembers,
          key: (member) => member as String,
          value: (_) => 1,
        );
        
        _splitPercentages = Map.fromIterable(
          _projectMembers,
          key: (member) => member as String,
          value: (_) => 100.0 / memberCount,
        );
        
        debugPrint('Split values reset successfully');
      });
    } catch (e, stackTrace) {
      debugPrint('Error resetting split values: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _saveExpense() async {
    debugPrint('Saving expense:');
    debugPrint('- Project ID: $_selectedProjectId');
    debugPrint('- Title: ${_titleController.text}');
    debugPrint('- Description: ${_descriptionController.text}');
    debugPrint('- Amount: ${_amountController.text}');
    debugPrint('- Category: $_selectedCategory');
    debugPrint('- Split Type: $_splitType');
    
    if (!_formKey.currentState!.validate() || _selectedProjectId == null) {
      debugPrint('Form validation failed or project not selected');
      return;
    }

    final amount = double.parse(_amountController.text);
    debugPrint('Creating splits for ${_projectMembers.length} members');
    final splits = _projectMembers.map((memberId) {
      double splitAmount;
      switch (_splitType) {
        case SplitType.equal:
          splitAmount = amount / _projectMembers.length;
          break;
        case SplitType.amount:
          splitAmount = _splitAmounts[memberId] ?? 0.0;
          break;
        case SplitType.shares:
          final totalShares = _splitShares.values.fold(0, (sum, shares) => sum + shares);
          splitAmount = amount * (_splitShares[memberId] ?? 0) / totalShares;
          break;
        case SplitType.percentage:
          splitAmount = amount * (_splitPercentages[memberId] ?? 0) / 100;
          break;
      }

      debugPrint('Split for member $memberId:');
      debugPrint('- Amount: $splitAmount');
      debugPrint('- Shares: ${_splitShares[memberId]}');
      debugPrint('- Percentage: ${_splitPercentages[memberId]}');

      return ExpenseSplit(
        userId: memberId,
        splitType: _splitType,
        amount: splitAmount,
        shares: _splitShares[memberId] ?? 1,
        percentage: _splitPercentages[memberId] ?? 0,
      );
    }).toList();

    final expense = Expense(
      id: const Uuid().v4(),
      projectId: _selectedProjectId!,
      title: _titleController.text,
      description: _descriptionController.text,
      amount: amount,
      category: _selectedCategory,
      paidById: widget.currentUserId ?? '',
      splits: splits,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      debugPrint('Saving expense to repository');
      await context.read<DataRepository>().addExpense(expense);
      debugPrint('Expense saved successfully');
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
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
      );
    }

    if (_userProjects.isEmpty) {
      return const Center(
        child: Text('No projects available. Please create a project first.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFormFields(),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields() {
    return [
      DropdownButtonFormField<String>(
        value: _selectedProjectId,
        decoration: const InputDecoration(
          labelText: 'Project',
          border: OutlineInputBorder(),
        ),
        items: _userProjects.map((project) {
          return DropdownMenuItem(
            value: project.id,
            child: Text(project.name),
          );
        }).toList(),
        onChanged: (projectId) {
          if (projectId != null) {
            setState(() {
              _selectedProjectId = projectId;
              _loadProjectMembers(projectId);
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select a project';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'Title',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a title';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Description',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _amountController,
        decoration: const InputDecoration(
          labelText: 'Amount',
          border: OutlineInputBorder(),
          prefixText: '\$',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an amount';
          }
          if (double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
        onChanged: (_) => _resetSplitValues(),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<ExpenseCategory>(
        value: _selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        items: ExpenseCategory.values.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Text(category.toString().split('.').last),
          );
        }).toList(),
        onChanged: (category) {
          if (category != null) {
            setState(() => _selectedCategory = category);
          }
        },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<SplitType>(
        value: _splitType,
        decoration: const InputDecoration(
          labelText: 'Split Type',
          border: OutlineInputBorder(),
        ),
        items: SplitType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.toString().split('.').last),
          );
        }).toList(),
        onChanged: (type) {
          if (type != null) {
            setState(() => _splitType = type);
          }
        },
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: _saveExpense,
        child: const Text('Save Expense'),
      ),
    ];
  }
} 