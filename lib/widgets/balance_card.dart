import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/balance_service.dart';
import '../services/cospend_api_service.dart';
import '../widgets/user_avatar.dart';

class BalanceCard extends StatefulWidget {
  final Project project;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final String userId;

  const BalanceCard({
    super.key,
    required this.project,
    required this.expenses,
    required this.settlements,
    required this.userId,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isLoading = true;
  late Map<String, double> _balances;
  late double _userBalance;
  late double _owed;
  late double _owing;
  final List<User> _members = [];
  final BalanceService _balanceService = BalanceService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(BalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses ||
        oldWidget.settlements != widget.settlements ||
        oldWidget.project.id != widget.project.id) {
      _initializeData();
    }
  }

  void _initializeData() {
    _calculateBalances();
    _initializeMembers();
  }

  void _initializeMembers() {
    _members.clear();
    for (String memberId in widget.project.memberIds) {
      _members.add(User(
        id: memberId,
        name: memberId,
        email: '',
      ));
    }
  }

  void _calculateBalances() {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      _balances = _balanceService.getProjectBalances(
        widget.project.id,
        widget.project.memberIds,
        widget.expenses,
        widget.settlements,
      );

      _userBalance = _balances[widget.userId] ?? 0.0;
      _owed = _userBalance > 0 ? _userBalance : 0.0;
      _owing = _userBalance < 0 ? -_userBalance : 0.0;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error calculating balances: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _balances = {};
          _userBalance = 0.0;
          _owed = 0.0;
          _owing = 0.0;
        });
      }
    }
  }

  Widget _buildMemberAvatars() {
    // Calculate total width needed for avatars with overlap
    final double avatarDiameter = 32.0;
    final double avatarOverlap = 16.0; // 50% overlap
    final double totalWidth = _members.isEmpty ? 0 : 
        avatarDiameter + ((_members.length - 1) * (avatarDiameter - avatarOverlap));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: totalWidth + 100, // Extra space for text
        maxHeight: avatarDiameter,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: totalWidth,
            height: avatarDiameter,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(
                _members.length,
                (index) => Positioned(
                  left: index * (avatarDiameter - avatarOverlap),
                  child: UserAvatar(
                    key: ValueKey(_members[index].id),
                    user: _members[index],
                    radius: avatarDiameter / 2,
                  ),
                ),
              ),
            ),
          ),
          if (_members.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              '${_members.length} members',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceRow(String label, double amount, Color? color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Balance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Text('Calculating balances...'),
              )
            else ...[
              _buildBalanceRow('You are owed', _owed, Colors.green[700]),
              const SizedBox(height: 8),
              _buildBalanceRow('You owe', _owing, Colors.red[700]),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildMemberAvatars(),
                  Text(
                    'Net: \$${_userBalance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _userBalance >= 0 ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 