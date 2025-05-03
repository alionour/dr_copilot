import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  final List<String> months = const [
    'يناير', 'فبراير', 'مارس', 'إبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  final List<int> revenue = const [
    0, 0, 0, 0, 250, 480, 960, 0, 600, 1440, 600, 600
  ];

  final List<int> expenses = const [
    0, 0, 2500, 2500, 4150, 4511, 4100, 4485, 3340, 7200, 6100, 4300
  ];

  @override
  Widget build(BuildContext context) {
    // Example data for two years
    final Map<String, List<int>> revenueByYear = {
      '2023': [0, 0, 0, 0, 100, 200, 300, 0, 400, 500, 600, 700],
      '2024': revenue,
    };
    final Map<String, List<int>> expensesByYear = {
      '2023': [0, 0, 1000, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000],
      '2024': expenses,
    };
    final List<String> years = revenueByYear.keys.toList();

    String selectedYear = years.last;

    return StatefulBuilder(
      builder: (context, setState) {
        final List<int> selectedRevenue = revenueByYear[selectedYear]!;
        final List<int> selectedExpenses = expensesByYear[selectedYear]!;
        final int totalRevenue = selectedRevenue.reduce((a, b) => a + b);
        final int totalExpenses = selectedExpenses.reduce((a, b) => a + b);
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('التقارير المالية لعام',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal)),
                              const SizedBox(width: 12),
                              // Beautiful dropdown using DropdownButtonFormField with custom style
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.teal.shade100, width: 1.2),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedYear,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.teal, size: 28),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                                    dropdownColor: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    items: years.map((year) {
                                      return DropdownMenuItem<String>(
                                        value: year,
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_month, color: Colors.teal.shade300, size: 22),
                                            const SizedBox(width: 8),
                                            Text(year, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
    // Use custom colors for expenses for better contrast
    final bool isExpenses = title == 'المصروفات';
    final Color headerColor = isExpenses ? const Color(0xFFFFB3B3) : Colors.green[200]!;
    final Color totalRowColor = isExpenses ? const Color(0xFFFFB3B3) : Colors.green[200]!;
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
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
                              fontWeight: FontWeight.bold, fontSize: 16, color: totalTextColor)),
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
