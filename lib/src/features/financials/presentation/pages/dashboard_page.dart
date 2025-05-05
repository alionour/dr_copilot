import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../navigation_side/presentation/bloc/navigation_bloc.dart';
import '../widgets/revenue_by_month_chart.dart';
import 'charts_page.dart' show ChartData;
import 'package:dr_copilot/src/features/financials/presentation/widgets/currency_profiles_section.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for chart
    final List<ChartData> chartData = [
      ChartData('Jan', 1000, 0, 0, 0),
      ChartData('Feb', 1200, 0, 0, 0),
      ChartData('Mar', 900, 0, 0, 0),
      ChartData('Apr', 1500, 0, 0, 0),
      ChartData('May', 1100, 0, 0, 0),
      ChartData('Jun', 1300, 0, 0, 0),
      ChartData('Jul', 1400, 0, 0, 0),
      ChartData('Aug', 1200, 0, 0, 0),
      ChartData('Sep', 1000, 0, 0, 0),
      ChartData('Oct', 1600, 0, 0, 0),
      ChartData('Nov', 900, 0, 0, 0),
      ChartData('Dec', 1400, 0, 0, 0),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Greeting and user info
          Builder(
            builder: (context) {
              final user =
                  context.select((NavigationBloc bloc) => bloc.state.user);
              if (user == null) return const SizedBox.shrink();
              return Row(
                children: [
                  if (user.photoURL != null && user.photoURL!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL!),
                      radius: 24,
                    ),
                  if (user.photoURL != null && user.photoURL!.isNotEmpty)
                    const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboardGreeting'
                            .tr(args: [user.displayName ?? user.email ?? '']),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (user.email != null)
                        Text(user.email!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          // 2. Summary cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 200,
                  child: _SummaryCard(
                    color: Colors.teal,
                    title: 'totalRevenue'.tr(),
                    value: '\u000024${12000.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: _SummaryCard(
                    color: Colors.redAccent,
                    title: 'totalExpenses'.tr(),
                    value: '\u000024${8000.toStringAsFixed(2)}',
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 200,
                  child: _SummaryCard(
                    color: Colors.blue,
                    title: 'sessionsCount'.tr(),
                    value: 320.toString(),
                    icon: Icons.event,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Only show RevenueByMonthChart
          RevenueByMonthChart(chartData: chartData),
          const SizedBox(height: 24),
          // Currency Profiles Section
          CurrencyProfilesSection(),
          const SizedBox(height: 24),
          // 4. Transactions Activity
          Text('transactionsActivity'.tr(),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (false) // Replace with transactions.isEmpty in real code
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('noTransactions'.tr(),
                      style: const TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Replace with transactions.length
              itemBuilder: (context, index) {
                // Replace with real transaction data
                final tx = {
                  'account': '1234',
                  'date': 'Feb 18, 2025',
                  'status': 'Completed',
                  'user': 'Jane Doe'
                };
                return ListTile(
                  leading: CircleAvatar(child: Text(tx['account']![0])),
                  title: Text('accountNumber'.tr(args: [tx['account']!])),
                  subtitle: Text('transactionDateStatus'
                      .tr(args: [tx['date']!, tx['status']!])),
                  trailing: Text('transactionUser'.tr(args: [tx['user']!])),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.color,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
