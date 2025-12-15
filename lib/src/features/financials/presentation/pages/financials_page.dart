import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/pages/transactions_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/charts_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/bills_and_payments_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/reports_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/goals_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/dashboard_page.dart';
import 'package:dr_copilot/src/core/helper/screen_size_helper.dart';

class FinancialsPage extends StatefulWidget {
  const FinancialsPage({super.key});

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

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

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We removed the top-level AppBar to avoid "double header" issues with sub-pages.
    // Each sub-page (Dashboard, Transactions, etc.) is responsible for its own AppBar if needed.

    final isSmall = ScreenSizeHelper.isSmall(context);

    if (isSmall) {
      // Mobile Layout: Bottom Navigation Bar
      return Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: 'dashboard'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.swap_horiz),
              selectedIcon: const Icon(Icons.swap_horiz),
              label: 'transactions'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.pie_chart_outline),
              selectedIcon: const Icon(Icons.pie_chart),
              label: 'charts'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'billsAndPayments'
                  .tr(), // Key might need verification or creation
            ),
            NavigationDestination(
              icon: const Icon(Icons.insert_chart_outlined),
              selectedIcon: const Icon(Icons.insert_chart),
              label: 'reports'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.flag_outlined),
              selectedIcon: const Icon(Icons.flag),
              label: 'goals'.tr(),
            ),
          ],
        ),
      );
    } else {
      // Desktop/Tablet Layout: Custom Sidebar Navigation
      return Scaffold(
        body: Row(
          children: [
            // Custom Sidebar matching main app navigation
            GestureDetector(
              onTap: _toggleSidebar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _isSidebarExpanded ? 240 : 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    if (_isSidebarExpanded)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'financials'.tr(),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    const Divider(height: 1),
                    // Navigation Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildNavItem(
                            context,
                            index: 0,
                            icon: Icons.dashboard_outlined,
                            selectedIcon: Icons.dashboard,
                            label: 'dashboard'.tr(),
                          ),
                          _buildNavItem(
                            context,
                            index: 1,
                            icon: Icons.swap_horiz,
                            selectedIcon: Icons.swap_horiz,
                            label: 'transactions'.tr(),
                          ),
                          _buildNavItem(
                            context,
                            index: 2,
                            icon: Icons.pie_chart_outline,
                            selectedIcon: Icons.pie_chart,
                            label: 'charts'.tr(),
                          ),
                          _buildNavItem(
                            context,
                            index: 3,
                            icon: Icons.receipt_long,
                            selectedIcon: Icons.receipt_long,
                            label: 'billsAndPayments'.tr(),
                          ),
                          _buildNavItem(
                            context,
                            index: 4,
                            icon: Icons.insert_chart_outlined,
                            selectedIcon: Icons.insert_chart,
                            label: 'reports'.tr(),
                          ),
                          _buildNavItem(
                            context,
                            index: 5,
                            icon: Icons.flag_outlined,
                            selectedIcon: Icons.flag,
                            label: 'goals'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      );
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    if (!_isSidebarExpanded) {
      // Collapsed state - icon only with tooltip
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Tooltip(
          message: label,
          child: Material(
            color: isSelected
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: () => _onItemTapped(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Expanded state - icon and label
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).iconTheme.color,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

