class AnalyticsData {
  final List<MonthlyRevenue> revenueData;
  final List<MonthlyPatients> patientGrowthData;
  final AppointmentStatusData appointmentStatusData;
  final List<ServiceUsage> topServicesData;

  AnalyticsData({
    required this.revenueData,
    required this.patientGrowthData,
    required this.appointmentStatusData,
    required this.topServicesData,
  });
}

class MonthlyRevenue {
  final String month;
  final double amount;

  MonthlyRevenue({required this.month, required this.amount});
}

class MonthlyPatients {
  final String month;
  final int count;

  MonthlyPatients({required this.month, required this.count});
}

class AppointmentStatusData {
  final int completed;
  final int pending;
  final int cancelled;

  AppointmentStatusData({
    required this.completed,
    required this.pending,
    required this.cancelled,
  });

  int get total => completed + pending + cancelled;
}

class ServiceUsage {
  final String serviceName;
  final int count;

  ServiceUsage({required this.serviceName, required this.count});
}
