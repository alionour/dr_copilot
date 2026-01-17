import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/app/notifiers/owner_notifier.dart';
import '../bloc/charts_bloc.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clinicId = context.watch<OwnerNotifier>().clinicId;

    if (clinicId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('chartsPageTitle'.tr())),
        body: Center(child: Text('noClinicSelected'.tr())),
      );
    }

    // Trigger data load
    context.read<ChartsBloc>().add(LoadChartsData(clinicId));

    return Scaffold(
      appBar: AppBar(
        title: Text('chartsPageTitle'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChartsBloc>().add(LoadChartsData(clinicId));
            },
          ),
        ],
      ),
      body: BlocBuilder<ChartsBloc, ChartsState>(
        builder: (context, state) {
          if (state is ChartsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChartsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ChartsBloc>().add(LoadChartsData(clinicId));
                    },
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is ChartsLoaded) {
            final data = state.data;

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 2;
                } else if (constraints.maxWidth > 800) {
                  crossAxisCount = 2;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.5,
                  children: [
                    _buildRevenueChart(data.revenueData),
                    _buildPatientGrowthChart(data.patientGrowthData),
                    _buildAppointmentStatusChart(data.appointmentStatusData),
                    _buildTopServicesChart(data.topServicesData),
                  ],
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRevenueChart(List revenueData) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: 'revenueTrend'.tr()),
        series: <CartesianSeries<dynamic, dynamic>>[
          LineSeries<dynamic, String>(
            dataSource: revenueData,
            xValueMapper: (data, _) => data.month,
            yValueMapper: (data, _) => data.amount,
            color: Colors.green,
            markerSettings: const MarkerSettings(isVisible: true),
          )
        ],
      ),
    );
  }

  Widget _buildPatientGrowthChart(List patientData) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: 'patientGrowth'.tr()),
        series: <CartesianSeries<dynamic, dynamic>>[
          ColumnSeries<dynamic, String>(
            dataSource: patientData,
            xValueMapper: (data, _) => data.month,
            yValueMapper: (data, _) => data.count,
            color: Colors.blue,
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusChart(dynamic statusData) {
    final chartData = [
      _PieData('Completed'.tr(), statusData.completed, Colors.green),
      _PieData('Pending'.tr(), statusData.pending, Colors.orange),
      _PieData('Cancelled'.tr(), statusData.cancelled, Colors.red),
    ];

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SfCircularChart(
        title: ChartTitle(text: 'appointmentStatus'.tr()),
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        series: <CircularSeries<dynamic, dynamic>>[
          PieSeries<_PieData, String>(
            dataSource: chartData,
            xValueMapper: (_PieData data, _) => data.category,
            yValueMapper: (_PieData data, _) => data.value,
            pointColorMapper: (_PieData data, _) => data.color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
  }

  Widget _buildTopServicesChart(List servicesData) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: 'topServices'.tr()),
        series: <CartesianSeries<dynamic, dynamic>>[
          BarSeries<dynamic, String>(
            dataSource: servicesData,
            xValueMapper: (data, _) => data.serviceName,
            yValueMapper: (data, _) => data.count,
            color: Colors.purple,
          )
        ],
      ),
    );
  }
}

class _PieData {
  _PieData(this.category, this.value, this.color);
  final String category;
  final int value;
  final Color color;
}
