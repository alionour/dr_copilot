import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../pages/charts_page.dart';

class RevenueByMonthChart extends StatelessWidget {
  final List<ChartData> chartData;
  const RevenueByMonthChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('revenueByMonth'.tr()),
        ChartCard(
          SfCartesianChart(
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
                borderRadius: const BorderRadius.all(Radius.circular(6)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
