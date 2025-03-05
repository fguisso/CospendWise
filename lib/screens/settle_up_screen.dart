import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';

class SettleUpScreen extends StatefulWidget {
  final String projectId;
  final String currentUserId;

  const SettleUpScreen({
    super.key,
    required this.projectId,
    required this.currentUserId,
  });

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  final DataRepository _dataRepository = DataRepository();
  final BalanceService _balanceService = BalanceService();
  
  late Project _project;
  late List<User> _members;
  late Map<String, double> _balances;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final project = _dataRepository.getProjectById(widget.projectId);
      if (project == null) {
        throw Exception('Project not found');
      }
      _project = project;

      // Get all members of the project
      _members = project.memberIds
          .map((id) => _dataRepository.getUserById(id))
          .whereType<User>()
          .toList();

      // Calculate balances
      final expenses = _dataRepository.getExpensesForProject(widget.projectId);
      final settlements = _dataRepository.getSettlementsForProject(widget.projectId);
      _balances = _balanceService.getProjectBalances(
        widget.projectId,
        project.memberIds,
        expenses,
        settlements,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createSettlement(String toUserId, double amount) async {
    try {
      await _dataRepository.createSettlement(
        projectId: widget.projectId,
        fromUserId: widget.currentUserId,
        toUserId: toUserId,
        amount: amount,
        date: DateTime.now(),
        status: SettlementStatus.pending,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlement created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating settlement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settle Up')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    final List<MapEntry<String, double>> sortedBalances = _balances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text('Settle Up - ${_project.name}'),
      ),
      body: ListView.builder(
        itemCount: sortedBalances.length,
        itemBuilder: (context, index) {
          final entry = sortedBalances[index];
          final user = _members.firstWhere(
            (m) => m.id == entry.key,
            orElse: () => User(
              id: entry.key,
              name: 'Unknown User',
              email: '',
            ),
          );
          final balance = entry.value;

          if (user.id == widget.currentUserId) {
            return const SizedBox.shrink();
          }

          return ListTile(
            leading: CircleAvatar(
              child: Text(user.name[0].toUpperCase()),
            ),
            title: Text(user.name),
            subtitle: Text(
              balance > 0
                  ? 'Owes you \$${balance.abs().toStringAsFixed(2)}'
                  : 'You owe \$${balance.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: balance > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: balance != 0
                ? TextButton(
                    onPressed: () => _createSettlement(
                      balance > 0 ? user.id : widget.currentUserId,
                      balance.abs(),
                    ),
                    child: const Text('Settle'),
                  )
                : null,
          );
        },
      ),
    );
  }
} 