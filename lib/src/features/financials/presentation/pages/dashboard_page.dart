import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          // Total Balance
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'totalBalance'.tr(),
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${'USD'.tr()} 424,540',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bill & Payments
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('profit'.tr()),
                        SizedBox(height: 8),
                        Text('USD 190,655'),
                        SizedBox(height: 8),
                        Text('Today\'s left in billing cycle (Feb 28, 2025)'),
                        SizedBox(height: 8),
                        Text('Pay Now', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('payments'.tr()),
                        SizedBox(height: 8),
                        Text('USD 4,200'),
                        SizedBox(height: 8),
                        Text('1 day left in billing cycle (Mar 1, 2025)'),
                        SizedBox(height: 8),
                        Text('Pay Now', style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transactions Activity
          Text(
            'transactionsActivity'.tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Replace with actual transaction count
              itemBuilder: (context, index) {
                return ListTile(
                  title: const Text('Account 6799'),
                  subtitle: const Text('Feb 17, 2025 - Pending'),
                  trailing: const Text('Adam Barba'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
