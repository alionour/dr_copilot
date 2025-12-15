import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../pages/charts_page.dart';

class TotalRevenueByMonthChart extends StatelessWidget {
  final List<ChartData> chartData;
  const TotalRevenueByMonthChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('totalRevenueByMonth'.tr()),
        ChartCard(
          SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <CartesianSeries<ChartData, String>>[
              ColumnSeries<ChartData, String>(
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
      ],
    );
  }
}

