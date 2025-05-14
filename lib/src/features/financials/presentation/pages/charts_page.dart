import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/charts_page_widgets/revenue_by_month_chart.dart';
import '../widgets/charts_page_widgets/sessions_revenue_by_month_chart.dart';
import '../widgets/charts_page_widgets/total_revenue_by_month_chart.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {


    return BlocBuilder<FinancialsBloc, FinancialsState>(
      builder: (context, state) {
        final now = DateTime.now();
        final year = now.year;
        // Prepare chart data for each month in the current year
        final List<ChartData> chartData = List.generate(12, (i) {
          final monthNum = i + 1;
          final key =
              '${year.toString().padLeft(4, '0')}-${monthNum.toString().padLeft(2, '0')}';
          final revenue = state.revenuePerMonth[key] ?? 0.0;
          final expenses = state.expensesPerMonth[key] ?? 0.0;
          // If you have sessionsRevenue per month, use it; else set to 0.0
          final sessionsRevenue =
              0.0; // TODO: Replace with real sessions revenue if available
          final totalRevenue = revenue + sessionsRevenue;
          return ChartData(
              key, revenue, expenses, sessionsRevenue, totalRevenue);
        });

        // Calculate total revenue and expenses for the pie chart
        final totalRevenue =
            chartData.fold<double>(0.0, (sum, d) => sum + d.revenue);
        final totalExpenses =
            chartData.fold<double>(0.0, (sum, d) => sum + d.expenses);

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
                RevenueByMonthChart(chartData: chartData),
                const SizedBox(height: 24),
                SessionsRevenueByMonthChart(chartData: chartData),
                const SizedBox(height: 24),
                TotalRevenueByMonthChart(chartData: chartData),
                const SizedBox(height: 24),
                SectionTitle('expensesByMonth'.tr()),
                ChartCard(
                  SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        name: 'expenses'.tr(),
                        dataSource: chartData,
                        xValueMapper: (d, _) => d.month,
                        yValueMapper: (d, _) => d.expenses,
                        color: Colors.redAccent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
                SectionTitle('revenueVsExpensesByMonth'.tr()),
                ChartCard(
                  SfCartesianChart(
                    legend: Legend(
                        isVisible: true, position: LegendPosition.bottom),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        name: 'revenue'.tr(),
                        dataSource: chartData,
                        xValueMapper: (d, _) => d.month,
                        yValueMapper: (d, _) => d.revenue,
                        color: Colors.green,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6)),
                      ),
                      ColumnSeries<ChartData, String>(
                        name: 'expenses'.tr(),
                        dataSource: chartData,
                        xValueMapper: (d, _) => d.month,
                        yValueMapper: (d, _) => d.expenses,
                        color: Colors.redAccent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
                SectionTitle('revenueToExpensesRatio'.tr()),
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
                          series: <CircularSeries<PieData, String>>[
                            PieSeries<PieData, String>(
                              dataSource: [
                                PieData(
                                    'revenue'.tr(), totalRevenue, Colors.green),
                                PieData('expenses'.tr(), totalExpenses,
                                    Colors.redAccent),
                              ],
                              xValueMapper: (PieData data, _) => data.label,
                              yValueMapper: (PieData data, _) => data.value,
                              pointColorMapper: (PieData data, _) => data.color,
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
      },
    );
  }
}

class ChartData {
  final String month;
  final double revenue;
  final double expenses;
  final double sessionsRevenue;
  final double totalRevenue;
  ChartData(this.month, this.revenue, this.expenses, this.sessionsRevenue,
      this.totalRevenue);
}

class PieData {
  final String label;
  final double value;
  final Color color;
  PieData(this.label, this.value, this.color);
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});
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

class ChartCard extends StatelessWidget {
  final Widget child;
  const ChartCard(this.child, {super.key});
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
