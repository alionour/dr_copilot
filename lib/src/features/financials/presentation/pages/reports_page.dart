import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/year_selector.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/financials_bloc.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late String selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year.toString();
  }

  @override
  Widget build(BuildContext context) {
    List<String> months = [
      'month_january',
      'month_february',
      'month_march',
      'month_april',
      'month_may',
      'month_june',
      'month_july',
      'month_august',
      'month_september',
      'month_october',
      'month_november',
      'month_december'
    ];
    months = months.map((month) => month.tr()).toList();

    return BlocBuilder<FinancialsBloc, FinancialsState>(
      builder: (context, state) {
        final revenueByYear = state.revenuePerMonth.keys
            .fold<Map<String, List<int>>>({}, (map, key) {
          final year = key.split('-')[0];
          final month = int.parse(key.split('-')[1]) - 1;
          map.putIfAbsent(year, () => List<int>.filled(12, 0));
          map[year]![month] = state.revenuePerMonth[key]?.toInt() ?? 0;
          return map;
        });

        final expensesByYear = state.expensesPerMonth.keys
            .fold<Map<String, List<int>>>({}, (map, key) {
          final year = key.split('-')[0];
          final month = int.parse(key.split('-')[1]) - 1;
          map.putIfAbsent(year, () => List<int>.filled(12, 0));
          map[year]![month] = state.expensesPerMonth[key]?.toInt() ?? 0;
          return map;
        });

        // Generate a reasonable list of years: current year + any years in data
        final Set<String> yearsSet = {};
        // Add last 5 years as default
        final currentYearInt = DateTime.now().year;
        for (int i = 0; i < 5; i++) {
          yearsSet.add((currentYearInt - i).toString());
        }
        // Add any years from data
        yearsSet.addAll(revenueByYear.keys);
        yearsSet.addAll(expensesByYear.keys);

        final List<String> years = yearsSet.toList()
          ..sort((a, b) => b.compareTo(a));

        // Add a fallback for selectedRevenue and selectedExpenses
        final List<int> selectedRevenue =
            revenueByYear[selectedYear] ?? List<int>.filled(12, 0);
        final List<int> selectedExpenses =
            expensesByYear[selectedYear] ?? List<int>.filled(12, 0);
        final int totalRevenue = selectedRevenue.isNotEmpty
            ? selectedRevenue.reduce((a, b) => a + b)
            : 0;
        final int totalExpenses = selectedExpenses.isNotEmpty
            ? selectedExpenses.reduce((a, b) => a + b)
            : 0;

        final isLoading = state is FinancialsLoading ||
            state.revenuePerMonth.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'financial_reports_for_year'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                YearSelector(
                  selectedYear: selectedYear,
                  years: years,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedYear = value;
                      });
                    }
                  },
                ),
              ],
            ),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildTable(
                  context,
                  title: 'income'.tr(),
                  year: selectedYear,
                  months: months,
                  values: selectedRevenue,
                  total: totalRevenue,
                  color: Colors.green[100]!,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),
                _buildTable(
                  context,
                  title: 'expenses'.tr(),
                  year: selectedYear,
                  months: months,
                  values: selectedExpenses,
                  total: totalExpenses,
                  color: Colors.red[100]!,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTable(
    BuildContext context, {
    required String title,
    required String year,
    required List<String> months,
    required List<int> values,
    required int total,
    required Color color,
    bool isLoading = false,
  }) {
    final bool isExpenses = title == 'expenses'.tr();
    final Color headerColor = Theme.of(context).colorScheme.primaryContainer;
    final Color totalRowColor =
        Theme.of(context).colorScheme.secondaryContainer;
    final Color tableBgColor = Theme.of(context).colorScheme.surface;
    final Color totalTextColor = isExpenses
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      color: tableBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
            const SizedBox(height: 8),
            Text(year,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              border: TableBorder.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  width: 0.5),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: headerColor),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('month_label'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ),
                  ],
                ),
                ...List.generate(months.length, (i) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(months[i],
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface,
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: isLoading
                            ? Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              )
                            : Text(values[i].toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).colorScheme.onSurface,
                                )),
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: totalRowColor),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('total_label'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: isLoading
                          ? Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: totalTextColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          : Text(total.toString(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: totalTextColor)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
