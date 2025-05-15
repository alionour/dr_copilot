import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';

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

        return _BarLineChartSwitcher(
            chartData: chartData,
            totalRevenue: totalRevenue,
            totalExpenses: totalExpenses);
      },
    );
  }
}

// Widget to switch between Bar and Line chart for revenue vs expenses
class _BarLineChartSwitcher extends StatefulWidget {
  final List<ChartData> chartData;
  final double totalRevenue;
  final double totalExpenses;
  const _BarLineChartSwitcher(
      {required this.chartData,
      required this.totalRevenue,
      required this.totalExpenses});

  @override
  State<_BarLineChartSwitcher> createState() => _BarLineChartSwitcherState();
}

class _BarLineChartSwitcherState extends State<_BarLineChartSwitcher> {
  bool showBar = true;

  @override
  Widget build(BuildContext context) {
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
            SectionTitle('revenueVsExpensesByMonth'.tr()),
            ChartCard(
              Stack(
                children: [
                  SfCartesianChart(
                    legend: Legend(
                        isVisible: true, position: LegendPosition.bottom),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: showBar
                        ? <CartesianSeries<ChartData, String>>[
                            ColumnSeries<ChartData, String>(
                              name: 'revenue'.tr(),
                              dataSource: widget.chartData,
                              xValueMapper: (d, _) => d.month,
                              yValueMapper: (d, _) => d.revenue,
                              color: Colors.green,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6)),
                            ),
                            ColumnSeries<ChartData, String>(
                              name: 'expenses'.tr(),
                              dataSource: widget.chartData,
                              xValueMapper: (d, _) => d.month,
                              yValueMapper: (d, _) => d.expenses,
                              color: Colors.redAccent,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(6)),
                            ),
                          ]
                        : <CartesianSeries<ChartData, String>>[
                            LineSeries<ChartData, String>(
                              name: 'revenue'.tr(),
                              dataSource: widget.chartData,
                              xValueMapper: (d, _) => d.month,
                              yValueMapper: (d, _) => d.revenue,
                              color: Colors.green,
                              markerSettings:
                                  const MarkerSettings(isVisible: true),
                            ),
                            LineSeries<ChartData, String>(
                              name: 'expenses'.tr(),
                              dataSource: widget.chartData,
                              xValueMapper: (d, _) => d.month,
                              yValueMapper: (d, _) => d.expenses,
                              color: Colors.redAccent,
                              markerSettings:
                                  const MarkerSettings(isVisible: true),
                            ),
                          ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: Tooltip(
                        message: showBar ? 'Show Line Chart' : 'Show Bar Chart',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            setState(() {
                              showBar = !showBar;
                            });
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              showBar ? Icons.show_chart : Icons.bar_chart,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // RevenueByMonthChart with toggle
            ChartCard(
              _ToggleableBarLineChart(
                chartData: widget.chartData,
                barName: 'revenue'.tr(),
                lineName: 'revenue'.tr(),
                color: Colors.green,
                yValueMapper: (d) => d.revenue,
              ),
            ),
            const SizedBox(height: 24),
            // SessionsRevenueByMonthChart with toggle
            ChartCard(
              _ToggleableBarLineChart(
                chartData: widget.chartData,
                barName: 'sessionsRevenue'.tr(),
                lineName: 'sessionsRevenue'.tr(),
                color: Colors.blue,
                yValueMapper: (d) => d.sessionsRevenue,
              ),
            ),
            const SizedBox(height: 24),
            // TotalRevenueByMonthChart with toggle
            ChartCard(
              _ToggleableBarLineChart(
                chartData: widget.chartData,
                barName: 'totalRevenue'.tr(),
                lineName: 'totalRevenue'.tr(),
                color: Colors.teal,
                yValueMapper: (d) => d.totalRevenue,
              ),
            ),

            const SizedBox(height: 24),
            SectionTitle('expensesByMonth'.tr()),
            ChartCard(
              _ToggleableBarLineChart(
                chartData: widget.chartData,
                barName: 'expenses'.tr(),
                lineName: 'expenses'.tr(),
                color: Colors.redAccent,
                yValueMapper: (d) => d.expenses,
              ),
            ),
            SectionTitle('revenueToExpensesRatio'.tr()),
            SizedBox(
              height: 260,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                            PieData('revenue'.tr(), widget.totalRevenue,
                                Colors.green),
                            PieData('expenses'.tr(), widget.totalExpenses,
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
                          radius: '75%',
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

// Toggleable Bar/Line Chart widget for single series
class _ToggleableBarLineChart extends StatefulWidget {
  final List<ChartData> chartData;
  final String barName;
  final String lineName;
  final Color color;
  final double Function(ChartData) yValueMapper;

  const _ToggleableBarLineChart({
    required this.chartData,
    required this.barName,
    required this.lineName,
    required this.color,
    required this.yValueMapper,
    Key? key,
  }) : super(key: key);

  @override
  State<_ToggleableBarLineChart> createState() =>
      _ToggleableBarLineChartState();
}

class _ToggleableBarLineChartState extends State<_ToggleableBarLineChart> {
  bool showBar = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SfCartesianChart(
          legend: Legend(isVisible: false),
          primaryXAxis: CategoryAxis(),
          primaryYAxis: NumericAxis(),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: showBar
              ? <CartesianSeries<ChartData, String>>[
                  ColumnSeries<ChartData, String>(
                    name: widget.barName,
                    dataSource: widget.chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => widget.yValueMapper(d),
                    color: widget.color,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ]
              : <CartesianSeries<ChartData, String>>[
                  LineSeries<ChartData, String>(
                    name: widget.lineName,
                    dataSource: widget.chartData,
                    xValueMapper: (d, _) => d.month,
                    yValueMapper: (d, _) => widget.yValueMapper(d),
                    color: widget.color,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            child: Tooltip(
              message: showBar ? 'Show Line Chart' : 'Show Bar Chart',
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() {
                    showBar = !showBar;
                  });
                },
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    showBar ? Icons.show_chart : Icons.bar_chart,
                    color: widget.color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
