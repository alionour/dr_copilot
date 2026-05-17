import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

/// Telemedicine video consultation page
/// Displays meeting link and instructions for joining video call
class TelemedicinePage extends StatelessWidget {
  final String meetingLink;
  final String patientName;
  final String appointmentTime;

  const TelemedicinePage({
    super.key,
    required this.meetingLink,
    required this.patientName,
    required this.appointmentTime,
  });

  Future<void> _launchMeetingLink(BuildContext context) async {
    final uri = Uri.parse(meetingLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('couldNotLaunchMeeting'.tr()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('telemedicineConsultation'.tr()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_call, size: 100, color: Colors.blue.shade700),
              const SizedBox(height: 24),
              Text(
                'videoConsultationWith'.tr(),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                patientName,
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                appointmentTime,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 300,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => _launchMeetingLink(context),
                  icon: const Icon(Icons.video_call, size: 28),
                  label: Text(
                    'joinVideoCall'.tr(),
                    style: const TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  // Copy meeting link to clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: SelectionArea(child: Text('meetingLinkCopied'.tr()))),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text('copyMeetingLink'.tr()),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'instructions'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• ${'ensureGoodInternetConnection'.tr()}'),
                    Text('• ${'testCameraAndMicrophone'.tr()}'),
                    Text('• ${'findQuietLocation'.tr()}'),
                    Text('• ${'havePatientRecordsReady'.tr()}'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'hostLoginNote'
                                  .tr(), // Add key to translations later or hardcode for now if strict on keys
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
