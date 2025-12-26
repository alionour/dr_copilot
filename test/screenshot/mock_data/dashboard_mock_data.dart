import 'package:dr_copilot/src/features/financials/presentation/widgets/dashboard_view.dart';

class DashboardMockData {
  static String get userName => 'Dr. Smith';
  static int get sessionsThisMonth => 42;
  static int get sessionsThisYear => 380;
  static int get evaluationsThisMonth => 15;
  static int get evaluationsThisYear => 125;
  static double get totalRevenueThisMonth => 12450.00;
  static double get totalExpensesThisMonth => 4200.00;

  static List<RecentTransaction> generateRecentTransactions() {
    final now = DateTime.now();

    return [
      RecentTransaction(
        id: 'txn_001',
        description: 'Patient Payment - Session #142',
        category: 'Income',
        amount: 150.00,
        isIncome: true,
        date: now.subtract(const Duration(hours: 2)),
      ),
      RecentTransaction(
        id: 'txn_002',
        description: 'Office Supplies',
        category: 'Expense',
        amount: 85.50,
        isIncome: false,
        date: now.subtract(const Duration(days: 1)),
      ),
      RecentTransaction(
        id: 'txn_003',
        description: 'Insurance Reimbursement',
        category: 'Income',
        amount: 450.00,
        isIncome: true,
        date: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      RecentTransaction(
        id: 'txn_004',
        description: 'Software Subscription',
        category: 'Expense',
        amount: 99.99,
        isIncome: false,
        date: now.subtract(const Duration(days: 2)),
      ),
      RecentTransaction(
        id: 'txn_005',
        description: 'Patient Payment - Evaluation',
        category: 'Income',
        amount: 200.00,
        isIncome: true,
        date: now.subtract(const Duration(days: 2, hours: 5)),
      ),
      RecentTransaction(
        id: 'txn_006',
        description: 'Equipment Maintenance',
        category: 'Expense',
        amount: 275.00,
        isIncome: false,
        date: now.subtract(const Duration(days: 3)),
      ),
      RecentTransaction(
        id: 'txn_007',
        description: 'Group Therapy Session',
        category: 'Income',
        amount: 350.00,
        isIncome: true,
        date: now.subtract(const Duration(days: 4)),
      ),
      RecentTransaction(
        id: 'txn_008',
        description: 'Utilities Payment',
        category: 'Expense',
        amount: 180.00,
        isIncome: false,
        date: now.subtract(const Duration(days: 4, hours: 6)),
      ),
      RecentTransaction(
        id: 'txn_009',
        description: 'Patient Payment - Follow-up',
        category: 'Income',
        amount: 120.00,
        isIncome: true,
        date: now.subtract(const Duration(days: 5)),
      ),
      RecentTransaction(
        id: 'txn_010',
        description: 'Professional Development Course',
        category: 'Expense',
        amount: 350.00,
        isIncome: false,
        date: now.subtract(const Duration(days: 6)),
      ),
    ];
  }
}
