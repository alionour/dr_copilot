import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../navigation_side/presentation/bloc/navigation_bloc.dart';
import '../widgets/charts_page_widgets/revenue_by_month_chart.dart';
import 'charts_page.dart' show ChartData;
import 'package:dr_copilot/src/features/financials/presentation/widgets/dashbaord_page_widgets/currency_profiles_section.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get real session/evaluation counts from FinancialsBloc state
    final financialsState = context.watch<FinancialsBloc>().state;
    final now = DateTime.now();
    final yearKey = now.year.toString().padLeft(4, '0');
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    final sessionsYear = financialsState.sessionsCountPerMonth[yearKey] ?? 0;
    final sessionsMonth = financialsState.sessionsCountPerMonth[monthKey] ?? 0;
    final evalsYear = financialsState.evaluationsCountPerMonth[yearKey] ?? 0;
    final evalsMonth = financialsState.evaluationsCountPerMonth[monthKey] ?? 0;
    final revenueMonth =
        financialsState.revenuePerMonth[monthKey]?.toStringAsFixed(2) ?? '...';
    final expensesMonth =
        financialsState.expensesPerMonth[monthKey]?.toStringAsFixed(2) ?? '...';
    // You can still use the mock chart data for the chart
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

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final bloc = context.read<FinancialsBloc>();
    //   final year = now.year;
    //   final month = now.month;
    //   bloc.add(GetSessionsCountForYear(year));
    //   bloc.add(GetSessionsCountForMonth(year, month));
    //   bloc.add(GetEvaluationsCountForYear(year));
    //   bloc.add(GetEvaluationsCountForMonth(year, month));
    //   // bloc.add(GetTotalRevenueForMonth(year, month));
    //   // bloc.add(FetchTotalExpensesForMonth(year, month));
    // });

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
          // 2. Summary cards (real session/evaluation counts)
          // 2. Summary cards (real session/evaluation counts) with visible scrollbar
          StatefulBuilder(
            builder: (context, setState) {
              final ScrollController _scrollController = ScrollController();
              return SizedBox(
                height: 160,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: BlocBuilder<FinancialsBloc, FinancialsState>(
                    builder: (context, state) {
                      return SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(width: 10,),
                            SizedBox(
                              width: 200,
                              child: _SummaryCard(
                                color: Colors.teal,
                                title: 'totalRevenue'.tr(),
                                value: state.revenuePerMonth[monthKey]?.toStringAsFixed(2) ?? '...',
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 200,
                              child: _SummaryCard(
                                color: Colors.redAccent,
                                title: 'totalExpenses'.tr(),
                                value: state.expensesPerMonth[monthKey]?.toStringAsFixed(2) ?? '...',
                                icon: Icons.trending_down,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Sessions Year
                            SizedBox(
                              width: 200,
                              child: _SummaryCard(
                                color: Colors.blue,
                                title: '${'sessionsCount'.tr()} (${now.year})',
                                value: sessionsYear.toString(),
                                icon: Icons.event,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Sessions Month
                            SizedBox(
                              width: 200,
                              child: _SummaryCard(
                                color: Colors.blue.shade700,
                                title:
                                    '${'sessionsCount'.tr()} (${DateFormat.MMMM(Localizations.localeOf(context).toString()).format(now)})',
                                value: sessionsMonth.toString(),
                                icon: Icons.event_available,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Evaluations Year
                            SizedBox(
                              width: 200,
                              child: _SummaryCard(
                                color: Colors.purple,
                                title: '${'evaluationsCount'.tr()} (${now.year})',
                                value: evalsYear.toString(),
                                icon: Icons.assignment,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Evaluations Month
                            SizedBox(
                              width: 200,
                              child: _SummaryCard(
                                color: Colors.purple.shade700,
                                title:
                                    '${'evaluationsCount'.tr()} (${DateFormat.MMMM(Localizations.localeOf(context).toString()).format(now)})',
                                value: evalsMonth.toString(),
                                icon: Icons.assignment_turned_in,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ),
              );
            },
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

class _SummaryCard extends StatefulWidget {
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
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => setState(() => _isHovered = !_isHovered),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.05))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text(widget.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
