import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Self check-in kiosk page for tablet mode
/// Allows patients to check themselves in by entering phone number
class KioskCheckInPage extends StatefulWidget {
  const KioskCheckInPage({super.key});

  @override
  State<KioskCheckInPage> createState() => _KioskCheckInPageState();
}

class _KioskCheckInPageState extends State<KioskCheckInPage> {
  final TextEditingController _phoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSearching = false;
  bool _showSuccess = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      // Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Search for appointments by phone number for today
      final querySnapshot = await _firestore
          .collection('calendar_events')
          .where('patientPhone', isEqualTo: _phoneController.text.trim())
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'No appointment found for this phone number today.';
        });
        return;
      }

      // If multiple appointments, show first one (or implement selection dialog)
      final appointmentDoc = querySnapshot.docs.first;
      final appointmentData = appointmentDoc.data();

      // Show confirmation dialog
      if (mounted) {
        final confirmed = await _showConfirmationDialog(appointmentData);

        if (confirmed == true) {
          // Update appointment status to 'arrived'
          await _firestore
              .collection('calendar_events')
              .doc(appointmentDoc.id)
              .update({'status': 'arrived', 'arrivedAt': Timestamp.now()});

          setState(() {
            _isSearching = false;
            _showSuccess = true;
          });

          // Auto-reset after 5 seconds
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _showSuccess = false;
                _phoneController.clear();
                _errorMessage = '';
              });
            }
          });
        } else {
          setState(() {
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<bool?> _showConfirmationDialog(Map<String, dynamic> appointment) {
    final startTime = (appointment['startTime'] as Timestamp).toDate();
    final timeStr = DateFormat('h:mm a').format(startTime);
    final doctorName = appointment['doctorName'] ?? 'the doctor';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirmAppointment'.tr()),
        content: SelectionArea(child: Text(
          'Do you have an appointment with $doctorName at $timeStr?',
          style: const TextStyle(fontSize: 20),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(20),
            ),
            child: Text('no'.tr(), style: const TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.blue,
            ),
            child: Text('yes'.tr(), style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 120, color: Colors.green.shade700),
              const SizedBox(height: 24),
              Text(
                'checkInSuccess'.tr(),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'pleaseHaveASeat'.tr(),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo/Header
                const Icon(Icons.medical_services,
                    size: 100, color: Colors.blue),
                const SizedBox(height: 32),

                Text(
                  'welcomeCheckIn'.tr(),
                  style: const TextStyle(
                      fontSize: 48, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Phone input
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(fontSize: 32),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'enterPhoneNumber'.tr(),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(24),
                      errorText: _errorMessage.isEmpty ? null : _errorMessage,
                    ),
                    onSubmitted: (_) => _checkIn(),
                  ),
                ),

                const SizedBox(height: 32),

                // Check-in button
                SizedBox(
                  width: 400,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _checkIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 28),
                    ),
                    child: _isSearching
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('checkIn'.tr()),
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  'kioskInstructions'.tr(),
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
