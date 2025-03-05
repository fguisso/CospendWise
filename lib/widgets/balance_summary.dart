import 'package:flutter/material.dart';

class BalanceSummary extends StatelessWidget {
  final double totalBalance;
  final double youOwe;
  final double youAreOwed;
  final VoidCallback onTap;

  const BalanceSummary({
    super.key,
    required this.totalBalance,
    required this.youOwe,
    required this.youAreOwed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalBalance >= 0
                    ? 'You are owed'
                    : 'You owe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: totalBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
              Text(
                '\$${totalBalance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: totalBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BalanceColumn(
                    icon: Icons.arrow_upward,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    title: 'you owe',
                    amount: youOwe,
                  ),
                  _BalanceColumn(
                    icon: Icons.arrow_downward,
                    iconColor: Colors.green,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    title: 'you are owed',
                    amount: youAreOwed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final double amount;

  const _BalanceColumn({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 