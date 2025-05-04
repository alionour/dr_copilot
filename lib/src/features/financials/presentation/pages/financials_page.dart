import 'package:dr_copilot/src/features/financials/transactions/data/remote/transactions_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/usecases/transactions_usecase.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/pages/transactions_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/charts_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/bills_and_payments_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/reports_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/goals_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/dashboard_page.dart';
import 'package:dr_copilot/src/core/helper/screen_size_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    ChartsPage(),
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
    final navMenuButton = NavMenuButtonProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('financials'.tr()),
        leading: Icon(Icons.attach_money_outlined),
        actions: [navMenuButton ?? SizedBox()],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: Center(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: ScreenSizeHelper.isSmall(context)
          ? SizedBox(
              height: 56, // Standard NavigationBar height
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.dashboard),
                    onPressed: () => _onItemTapped(0),
                    color: _selectedIndex == 0
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => _onItemTapped(1),
                    color: _selectedIndex == 1
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.pie_chart),
                    onPressed: () => _onItemTapped(2),
                    color: _selectedIndex == 2
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt),
                    onPressed: () => _onItemTapped(3),
                    color: _selectedIndex == 3
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.insert_chart),
                    onPressed: () => _onItemTapped(4),
                    color: _selectedIndex == 4
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.flag),
                    onPressed: () => _onItemTapped(5),
                    color: _selectedIndex == 5
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ],
              ),
            )
          : NavigationBar(
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
                  icon: Icon(Icons.pie_chart),
                  label: 'Charts',
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
