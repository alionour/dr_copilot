import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class WaitingListWidget extends StatelessWidget {
  final List<dynamic> scheduleItems;
  final String clinicName;

  const WaitingListWidget({
    super.key,
    this.scheduleItems = const [],
    this.clinicName = 'Dr. AI Clinic',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: double.infinity,
          child: Column(
            children: [
              Text(
                'todaysSchedule'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                clinicName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: scheduleItems.isEmpty
              ? Center(
                  child: Text(
                    'noAppointments'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: scheduleItems.length,
                  itemBuilder: (context, index) {
                    final item = scheduleItems[index] as Map<String, dynamic>;
                    final title = item['title'] ?? 'appointment'.tr();
                    final startTimeStr = item['startTime'] as String?;

                    String timeDisplay = '--:--';
                    if (startTimeStr != null) {
                      final dt = DateTime.tryParse(startTimeStr);
                      if (dt != null) {
                        timeDisplay =
                            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                    }

                    // Simple "Now" logic if it's the first item?
                    // Or check time? For now, let's just show the list.
                    // Highlighting the first one as "Up Next" or "Current" is a reasonable default
                    // if we assume sorted by time.
                    final isCurrent = index == 0;

                    return Card(
                      elevation: isCurrent ? 4 : 1,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeDisplay,
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(item['eventType'] ?? 'appointment'.tr()),
                        trailing: isCurrent
                            ? Icon(Icons.arrow_forward_ios,
                                color: Theme.of(context).primaryColor)
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
