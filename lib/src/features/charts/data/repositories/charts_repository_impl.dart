import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../domain/models/analytics_model.dart';
import '../../domain/repositories/charts_repository.dart';

class ChartsRepositoryImpl implements ChartsRepository {
  final FirebaseFirestore firestore;

  ChartsRepositoryImpl({required this.firestore});

  @override
  Future<Either<Failure, AnalyticsData>> getAnalyticsData(
      String clinicId) async {
    try {
      // Calculate date range (last 12 months)
      final now = DateTime.now();
      final twelveMonthsAgo = DateTime(now.year - 1, now.month, 1);

      // Fetch all data concurrently
      final results = await Future.wait([
        _getRevenueData(clinicId, twelveMonthsAgo),
        _getPatientGrowthData(clinicId, twelveMonthsAgo),
        _getAppointmentStatusData(clinicId),
        _getTopServicesData(clinicId),
      ]);

      return Right(AnalyticsData(
        revenueData: results[0] as List<MonthlyRevenue>,
        patientGrowthData: results[1] as List<MonthlyPatients>,
        appointmentStatusData: results[2] as AppointmentStatusData,
        topServicesData: results[3] as List<ServiceUsage>,
      ));
    } catch (e) {
      return Left(ServerFailure('Failed to load analytics data: $e', 500));
    }
  }

  Future<List<MonthlyRevenue>> _getRevenueData(
      String clinicId, DateTime startDate) async {
    final snapshot = await firestore
        .collection('transactions')
        .where('clinicId', isEqualTo: clinicId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .get();

    // Group by month
    final Map<String, double> monthlyRevenue = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      if (dateStr != null) {
        try {
          final date = DateTime.parse(dateStr);
          final monthKey = DateFormat('MMM yyyy').format(date);
          monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + amount;
        } catch (_) {}
      }
    }

    // Convert to list and fill missing months with zero
    final List<MonthlyRevenue> result = [];
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(date);
      result.add(MonthlyRevenue(
        month: DateFormat('MMM').format(date),
        amount: monthlyRevenue[monthKey] ?? 0.0,
      ));
    }

    return result;
  }

  Future<List<MonthlyPatients>> _getPatientGrowthData(
      String clinicId, DateTime startDate) async {
    final snapshot = await firestore
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .get();

    // Group by month
    final Map<String, int> monthlyPatients = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final createdAtStr = data['createdAt'] as String?;

      if (createdAtStr != null) {
        try {
          final date = DateTime.parse(createdAtStr);
          final monthKey = DateFormat('MMM yyyy').format(date);
          monthlyPatients[monthKey] = (monthlyPatients[monthKey] ?? 0) + 1;
        } catch (_) {}
      }
    }

    // Convert to list and fill missing months with zero
    final List<MonthlyPatients> result = [];
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(date);
      result.add(MonthlyPatients(
        month: DateFormat('MMM').format(date),
        count: monthlyPatients[monthKey] ?? 0,
      ));
    }

    return result;
  }

  Future<AppointmentStatusData> _getAppointmentStatusData(
      String clinicId) async {
    // Get appointments for current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snapshot = await firestore
        .collection('appointments')
        .where('clinicId', isEqualTo: clinicId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();

    int completed = 0;
    int pending = 0;
    int cancelled = 0;

    for (var doc in snapshot.docs) {
      final status = (doc.data()['status'] as String?)?.toLowerCase() ?? '';
      if (status == 'completed' || status == 'done') {
        completed++;
      } else if (status == 'cancelled' || status == 'canceled') {
        cancelled++;
      } else {
        pending++;
      }
    }

    return AppointmentStatusData(
      completed: completed,
      pending: pending,
      cancelled: cancelled,
    );
  }

  Future<List<ServiceUsage>> _getTopServicesData(String clinicId) async {
    // Get sessions from last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

    final snapshot = await firestore
        .collection('sessions')
        .where('clinicId', isEqualTo: clinicId)
        .where('createdAt',
            isGreaterThanOrEqualTo: threeMonthsAgo.toIso8601String())
        .get();

    // Count by service/type
    final Map<String, int> serviceCounts = {};
    for (var doc in snapshot.docs) {
      final type = doc.data()['type'] as String? ?? 'Unknown';
      serviceCounts[type] = (serviceCounts[type] ?? 0) + 1;
    }

    // Sort and get top 5
    final sortedServices = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedServices
        .take(5)
        .map((e) => ServiceUsage(serviceName: e.key, count: e.value))
        .toList();
  }
}
