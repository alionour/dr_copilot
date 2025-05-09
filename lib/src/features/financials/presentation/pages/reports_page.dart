import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/financials_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  final List<String> months = const [
    'يناير',
    'فبراير',
    'مارس',
    'إبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر'
  ];

  @override
  Widget build(BuildContext context) {
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

        // Debugging: Print the revenue and expenses maps
        debugPrint('RevenueByYear: \n');
        revenueByYear.forEach((year, values) {
          debugPrint('$year: $values');
        });

        debugPrint('ExpensesByYear: \n');
        expensesByYear.forEach((year, values) {
          debugPrint('$year: $values');
        });

        final List<String> years = revenueByYear.keys.toList();

        // Ensure all years have 12 months populated with default values
        for (final year in years) {
          revenueByYear.putIfAbsent(year, () => List<int>.filled(12, 0));
          expensesByYear.putIfAbsent(year, () => List<int>.filled(12, 0));
        }

        String selectedYear =
            years.isNotEmpty ? years.last : DateTime.now().year.toString();

        return StatefulBuilder(
          builder: (context, setState) {
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

            return Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isSmall = constraints.maxWidth < 700;
                          return Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('التقارير المالية لعام',
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal)),
                                    const SizedBox(width: 12),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.teal.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                            color: Colors.teal.shade100,
                                            width: 1.2),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedYear,
                                          icon: const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Colors.teal,
                                              size: 28),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal),
                                          dropdownColor: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          items: years.map((year) {
                                            return DropdownMenuItem<String>(
                                              value: year,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.calendar_month,
                                                      color:
                                                          Colors.teal.shade300,
                                                      size: 22),
                                                  const SizedBox(width: 8),
                                                  Text(year,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                selectedYear = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              isSmall
                                  ? Column(
                                      children: [
                                        _buildTable(
                                          context,
                                          title: 'الإيرادات',
                                          year: selectedYear,
                                          months: months,
                                          values: selectedRevenue,
                                          total: totalRevenue,
                                          color: Colors.green[100]!,
                                        ),
                                        const SizedBox(height: 24),
                                        _buildTable(
                                          context,
                                          title: 'المصروفات',
                                          year: selectedYear,
                                          months: months,
                                          values: selectedExpenses,
                                          total: totalExpenses,
                                          color: Colors.red[100]!,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildTable(
                                            context,
                                            title: 'الإيرادات',
                                            year: selectedYear,
                                            months: months,
                                            values: selectedRevenue,
                                            total: totalRevenue,
                                            color: Colors.green[100]!,
                                          ),
                                        ),
                                        const SizedBox(width: 32),
                                        Expanded(
                                          child: _buildTable(
                                            context,
                                            title: 'المصروفات',
                                            year: selectedYear,
                                            months: months,
                                            values: selectedExpenses,
                                            total: totalExpenses,
                                            color: Colors.red[100]!,
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
  }) {
    final bool isExpenses = title == 'المصروفات';
    final Color headerColor =
        isExpenses ? const Color(0xFFFFB3B3) : Colors.green[200]!;
    final Color totalRowColor =
        isExpenses ? const Color(0xFFFFB3B3) : Colors.green[200]!;
    final Color tableBgColor = isExpenses ? const Color(0xFFFFE5E5) : color;
    final Color totalTextColor = isExpenses ? Colors.red[800]! : Colors.teal;

    return Card(
      color: tableBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(year, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
              },
              border: TableBorder.all(color: Colors.white, width: 0.5),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: headerColor),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('الشهر',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.teal)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.teal)),
                    ),
                  ],
                ),
                ...List.generate(months.length, (i) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(months[i],
                            style: const TextStyle(fontSize: 15)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(values[i].toString(),
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: totalRowColor),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('الإجمالي',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.teal)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(total.toString(),
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
