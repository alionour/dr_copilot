import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Kiosk Management Page - Generate and manage kiosk access links
class KioskManagementPage extends StatefulWidget {
  final String? clinicId;

  const KioskManagementPage({
    super.key,
    this.clinicId,
  });

  @override
  State<KioskManagementPage> createState() => _KioskManagementPageState();
}

class _KioskManagementPageState extends State<KioskManagementPage> {
  final _firestore = FirebaseFirestore.instance;
  String? _generatedLink;
  String? _clinicId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinicId();
  }

  Future<void> _loadClinicId() async {
    if (widget.clinicId != null) {
      setState(() {
        _clinicId = widget.clinicId;
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await sl<AbstractAuthRepository>().getCurrentUser();
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectionArea(child: Text('errorLoadingUser'.tr(args: [failure.message])))),
            );
          }
        },
        (user) {
          if (mounted) {
            setState(() {
              _clinicId = user?.primaryClinicId;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading clinic ID: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateKioskLink() async {
    if (_clinicId == null) return;

    try {
      // 1. Check for existing active links
      final activeLinksSnapshot = await _firestore
          .collection('clinics')
          .doc(_clinicId)
          .collection('kiosk_tokens')
          .where('active', isEqualTo: true)
          .get();

      if (activeLinksSnapshot.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: SelectionArea(child: Text('maxActiveLinksReached'.tr())),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final token = const Uuid().v4();

      await _firestore
          .collection('clinics')
          .doc(_clinicId)
          .collection('kiosk_tokens')
          .doc(token)
          .set({
        'token': token,
        'clinicId': _clinicId,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsedAt': null,
        'expiresAt': null, // null = never expires, or set a date
      });

      // Production Backend URL with clinicId param for direct lookup
      final link =
          'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/kiosk.html?token=$token&clinicId=$_clinicId';

      setState(() {
        _generatedLink = link;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('kioskLinkGenerated'.tr()))),
        );
        // Requirement 1: Instantly show QR code
        _showQrCode(link);
      }

      // Requirement 3: Auto-delete revoked links > 7 days old
      // Run in background (fire-and-forget) to not block UI
      _cleanupOldTokens();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('errorMessage'.tr(args: [e.toString()])))),
        );
      }
    }
  }

  Future<void> _cleanupOldTokens() async {
    if (_clinicId == null) return;
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final oldRevokedSnapshot = await _firestore
          .collection('clinics')
          .doc(_clinicId)
          .collection('kiosk_tokens')
          .where('active', isEqualTo: false)
          .where('createdAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldRevokedSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (oldRevokedSnapshot.docs.isNotEmpty) {
        await batch.commit();
        debugPrint(
            'Cleaned up ${oldRevokedSnapshot.docs.length} old revoked kiosk tokens');
      }
    } catch (e) {
      debugPrint('Error cleaning up old tokens: $e');
    }
  }

  Future<void> _revokeToken(String token) async {
    if (_clinicId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('revokeKioskLink'.tr()),
        content: SelectionArea(child: Text('revokeKioskLinkConfirmation'.tr())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('revoke'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore
          .collection('clinics')
          .doc(_clinicId)
          .collection('kiosk_tokens')
          .doc(token)
          .update({'active': false});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('kioskLinkRevoked'.tr()))),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: SelectionArea(child: Text('copiedToClipboard'.tr()))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_clinicId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('kioskManagement'.tr())),
        body: Center(child: Text('errorNoClinicId'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('kioskManagement'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: _loadClinicId,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Remote Booking Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.public,
                                color: Theme.of(context).colorScheme.primary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'remoteBooking'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'shareWithPatients'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/booking.html?clinicId=$_clinicId',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text:
                                        'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/booking.html?clinicId=$_clinicId'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: SelectionArea(child: Text('linkCopied'.tr()))),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data:
                                'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/booking.html?clinicId=$_clinicId',
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'scanToBook'.tr(),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Kiosk Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.tablet_mac,
                          size: 64, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'generateKioskLinkTitle'.tr(),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'generateKioskLinkDescription'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _generateKioskLink,
                        icon: const Icon(Icons.add_link),
                        label: Text('generateNewLink'.tr()),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      if (_generatedLink != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      _generatedLink!,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showQrCode(_generatedLink!),
                                    icon: Icon(Icons.qr_code,
                                        color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green),
                                    tooltip: 'showQrCode'.tr(),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _copyToClipboard(_generatedLink!),
                                    icon: const Icon(Icons.copy),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'shareThisLinkWithTablet'.tr(),
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'activeKioskLinks'.tr(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('clinics')
                    .doc(_clinicId)
                    .collection('kiosk_tokens')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tokens = snapshot.data!.docs;

                  if (tokens.isEmpty) {
                    return Center(
                      child: Text('noActiveKioskLinks'.tr()),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tokens.length,
                    itemBuilder: (context, index) {
                      final tokenData =
                          tokens[index].data() as Map<String, dynamic>;
                      final token = tokenData['token'] as String;
                      final active = tokenData['active'] as bool;
                      final createdAt = tokenData['createdAt'] as Timestamp?;
                      final lastUsedAt = tokenData['lastUsedAt'] as Timestamp?;

                      // Use backend URL
                      // Use backend URL with clinicId
                      final link =
                          'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/kiosk.html?token=$token&clinicId=$_clinicId';

                      return Card(
                        color: active ? null : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.grey.shade100),
                        child: ListTile(
                          leading: Icon(
                            active ? Icons.check_circle : Icons.cancel,
                            color: active ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            'kioskLink'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration:
                                  active ? null : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${'created'.tr()}: ${createdAt != null ? DateFormat('MMM dd, yyyy h:mm a').format(createdAt.toDate()) : 'N/A'}',
                              ),
                              if (lastUsedAt != null)
                                Text(
                                  '${'lastUsed'.tr()}: ${DateFormat('MMM dd, yyyy h:mm a').format(lastUsedAt.toDate())}',
                                ),
                              Text(
                                '${'status'.tr()}: ${active ? 'active'.tr() : 'revoked'.tr()}',
                                style: TextStyle(
                                  color: active ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showQrCode(link),
                                icon: const Icon(Icons.qr_code),
                                tooltip: 'showQrCode'.tr(),
                              ),
                              IconButton(
                                onPressed: () => _copyToClipboard(link),
                                icon: const Icon(Icons.copy),
                                tooltip: 'copyLink'.tr(),
                              ),
                              if (active)
                                IconButton(
                                  onPressed: () => _revokeToken(token),
                                  icon: const Icon(Icons.block),
                                  color: Colors.red,
                                  tooltip: 'revokeLink'.tr(),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrCode(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('kioskQrCode'.tr()),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 280.0,
              ),
            ),
          ),
        ), // Fixed: Removed unsupported gapless enum
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }
}
