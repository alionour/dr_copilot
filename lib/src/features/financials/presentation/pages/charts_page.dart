import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> months = [
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
    final List<double> revenue = [
      0,
      0,
      0,
      0,
      250,
      480,
      960,
      0,
      600,
      1440,
      600,
      600
    ];
    final List<double> sessionsRevenue = [
      0,
      0,
      0,
      0,
      100,
      200,
      400,
      0,
      300,
      700,
      300,
      300
    ]; // Mock data
    final List<double> totalRevenue =
        List.generate(months.length, (i) => revenue[i] + sessionsRevenue[i]);
    final List<double> expenses = [
      0,
      0,
      2500,
      2500,
      4150,
      4511,
      4100,
      4485,
      3340,
      7200,
      6100,
      4300
    ];
    final List<_ChartData> chartData = List.generate(
      months.length,
      (i) => _ChartData(months[i], revenue[i], expenses[i], sessionsRevenue[i],
          totalRevenue[i]),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('financialCharts').tr(),
        centerTitle: true,
        backgroundColor: Colors.green[200],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle('revenueByMonth'.tr()),
            _ChartCard(
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    name: 'revenue'.tr(),
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => d.revenue,
                    color: Colors.green,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
            _SectionTitle('sessionsRevenueByMonth'.tr()),
            _ChartCard(
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    name: 'sessionsRevenue'.tr(),
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => d.sessionsRevenue,
                    color: Colors.blue,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
            _SectionTitle('totalRevenueByMonth'.tr()),
            _ChartCard(
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    name: 'totalRevenue'.tr(),
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => d.totalRevenue,
                    color: Colors.teal,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
            _SectionTitle('expensesByMonth'.tr()),
            _ChartCard(
              SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    name: 'expenses'.tr(),
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => d.expenses,
                    color: Colors.redAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
            _SectionTitle('revenueVsExpensesByMonth'.tr()),
            _ChartCard(
              SfCartesianChart(
                legend:
                    Legend(isVisible: true, position: LegendPosition.bottom),
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<_ChartData, String>>[
                  ColumnSeries<_ChartData, String>(
                    name: 'revenue'.tr(),
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => d.revenue,
                    color: Colors.green,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  ColumnSeries<_ChartData, String>(
                    name: 'expenses'.tr(),
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => d.expenses,
                    color: Colors.redAccent,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
            _SectionTitle('revenueToExpensesRatio'.tr()),
            SizedBox(
              height: 260,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0), // Increased horizontal padding
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SfCircularChart(
                      legend: Legend(
                          isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries<_PieData, String>>[
                        PieSeries<_PieData, String>(
                          dataSource: [
                            _PieData('revenue'.tr(),
                                revenue.reduce((a, b) => a + b), Colors.green),
                            _PieData(
                                'expenses'.tr(),
                                expenses.reduce((a, b) => a + b),
                                Colors.redAccent),
                          ],
                          xValueMapper: (_PieData data, _) => data.label,
                          yValueMapper: (_PieData data, _) => data.value,
                          pointColorMapper: (_PieData data, _) => data.color,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 13),
                            connectorLineSettings: ConnectorLineSettings(
                                type: ConnectorType.curve, length: '15%'),
                          ),
                          radius: '75%', // Reduced radius for more space
                          explode: true,
                          explodeIndex: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final String month;
  final double revenue;
  final double expenses;
  final double sessionsRevenue;
  final double totalRevenue;
  _ChartData(this.month, this.revenue, this.expenses, this.sessionsRevenue,
      this.totalRevenue);
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData(this.label, this.value, this.color);
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard(this.child);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
