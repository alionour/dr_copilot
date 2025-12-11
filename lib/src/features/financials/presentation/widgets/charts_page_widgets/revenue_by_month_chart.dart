import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/charts_page.dart';

class RevenueByMonthChart extends StatelessWidget {
  final List<ChartData> chartData;
  const RevenueByMonthChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'revenueByMonth'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  dashArray: <double>[5, 5],
                ),
                axisLine: const AxisLine(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                header: '',
                canShowMarker: false,
                format: 'point.y',
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                textStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              series: <CartesianSeries<ChartData, String>>[
                ColumnSeries<ChartData, String>(
                  name: 'revenue'.tr(),
                  dataSource: chartData,
                  xValueMapper: (d, _) => d.month,
                  yValueMapper: (d, _) => d.revenue,
                  color: Colors.teal.shade400,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  width: 0.6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
