import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/transactions_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/wallet_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/bills_and_payments_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/reports_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/goals_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/dashboard_page.dart';

class FinancialsPage extends StatefulWidget {
  const FinancialsPage({super.key});

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    TransactionsPage(),
    WalletPage(),
    BillsAndPaymentsPage(),
    ReportsPage(),
    GoalsPage(),
  ];

  // Ensure _selectedIndex is within the valid range of the _pages list
  void _onItemTapped(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt),
            label: 'Bills & Payments',
          ),
          NavigationDestination(
            icon: Icon(Icons.insert_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag),
            label: 'Goals',
          ),
        ],
      ),
    );
  }
}
