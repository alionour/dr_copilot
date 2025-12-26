import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  final String userName;
  final int sessionsThisMonth;
  final int sessionsThisYear;
  final int evaluationsThisMonth;
  final int evaluationsThisYear;
  final double totalRevenueThisMonth;
  final double totalExpensesThisMonth;
  final List<RecentTransaction> recentTransactions;

  const DashboardView({
    super.key,
    required this.userName,
    required this.sessionsThisMonth,
    required this.sessionsThisYear,
    required this.evaluationsThisMonth,
    required this.evaluationsThisYear,
    required this.totalRevenueThisMonth,
    required this.totalExpensesThisMonth,
    required this.recentTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final netIncome = totalRevenueThisMonth - totalExpensesThisMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        leading: const Icon(Icons.dashboard),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Welcome back, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SummaryCard(
                  title: 'Sessions',
                  monthValue: sessionsThisMonth,
                  yearValue: sessionsThisYear,
                  icon: Icons.event_note,
                  color: Colors.blue,
                ),
                _SummaryCard(
                  title: 'Evaluations',
                  monthValue: evaluationsThisMonth,
                  yearValue: evaluationsThisYear,
                  icon: Icons.assessment,
                  color: Colors.purple,
                ),
                _SummaryCard(
                  title: 'Revenue',
                  monthValue: totalRevenueThisMonth.toInt(),
                  yearValue: null,
                  icon: Icons.attach_money,
                  color: Colors.green,
                  isCurrency: true,
                ),
                _SummaryCard(
                  title: 'Expenses',
                  monthValue: totalExpensesThisMonth.toInt(),
                  yearValue: null,
                  icon: Icons.money_off,
                  color: Colors.red,
                  isCurrency: true,
                ),
                _SummaryCard(
                  title: 'Net Income',
                  monthValue: netIncome.toInt(),
                  yearValue: null,
                  icon: Icons.trending_up,
                  color: netIncome >= 0 ? Colors.green : Colors.red,
                  isCurrency: true,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (recentTransactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No recent transactions'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = recentTransactions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: transaction.isIncome
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: Icon(
                          transaction.isIncome
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color:
                              transaction.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(transaction.category),
                      trailing: Text(
                        '\$${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              transaction.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int monthValue;
  final int? yearValue;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const _SummaryCard({
    required this.title,
    required this.monthValue,
    this.yearValue,
    required this.icon,
    required this.color,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isCurrency ? '\$$monthValue' : '$monthValue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (yearValue != null) ...[
            const SizedBox(height: 4),
            Text(
              'Year: ${isCurrency ? '\$$yearValue' : '$yearValue'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple model for transactions
class RecentTransaction {
  final String id;
  final String description;
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;

  const RecentTransaction({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}
