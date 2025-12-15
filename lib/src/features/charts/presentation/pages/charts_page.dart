import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('chartsPageTitle'.tr()),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 2;
          }
          return GridView.count(
            crossAxisCount: crossAxisCount,
            children: [
              Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  title: ChartTitle(text: 'Chart 1'),
                  series: <CartesianSeries<dynamic, dynamic>>[
                    ColumnSeries<ChartData, String>(
                      dataSource: [
                        ChartData('Jan', 35),
                        ChartData('Feb', 28),
                        ChartData('Mar', 34),
                        ChartData('Apr', 32),
                        ChartData('May', 40),
                        ChartData('Jun', 45),
                        ChartData('Jul', 50),
                        ChartData('Aug', 55),
                        ChartData('Sep', 60),
                        ChartData('Oct', 65),
                        ChartData('Nov', 70),
                        ChartData('Dec', 75)
                      ],
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  title: ChartTitle(text: 'Chart 2'),
                  series: <CartesianSeries<dynamic, dynamic>>[
                    LineSeries<ChartData, String>(
                      dataSource: [
                        ChartData('Jan', 20),
                        ChartData('Feb', 30),
                        ChartData('Mar', 25),
                        ChartData('Apr', 35),
                        ChartData('May', 45),
                        ChartData('Jun', 50),
                        ChartData('Jul', 55),
                        ChartData('Aug', 60),
                        ChartData('Sep', 65),
                        ChartData('Oct', 70),
                        ChartData('Nov', 75),
                        ChartData('Dec', 80)
                      ],
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  title: ChartTitle(text: 'Chart 3'),
                  series: <CartesianSeries<dynamic, dynamic>>[
                    BarSeries<ChartData, String>(
                      dataSource: [
                        ChartData('Jan', 15),
                        ChartData('Feb', 25),
                        ChartData('Mar', 20),
                        ChartData('Apr', 30),
                        ChartData('May', 35),
                        ChartData('Jun', 40),
                        ChartData('Jul', 45),
                        ChartData('Aug', 50),
                        ChartData('Sep', 55),
                        ChartData('Oct', 60),
                        ChartData('Nov', 65),
                        ChartData('Dec', 70)
                      ],
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  title: ChartTitle(text: 'Chart 4'),
                  series: <CartesianSeries<dynamic, dynamic>>[
                    SplineSeries<ChartData, String>(
                      dataSource: [
                        ChartData('Jan', 10),
                        ChartData('Feb', 15),
                        ChartData('Mar', 25),
                        ChartData('Apr', 20),
                        ChartData('May', 30),
                        ChartData('Jun', 35),
                        ChartData('Jul', 40),
                        ChartData('Aug', 45),
                        ChartData('Sep', 50),
                        ChartData('Oct', 55),
                        ChartData('Nov', 60),
                        ChartData('Dec', 65)
                      ],
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}

