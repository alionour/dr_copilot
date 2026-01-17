import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';

abstract class BaseActionHandler {
  final OwnerNotifier ownerNotifier;
  final PermissionService permissionService;

  BaseActionHandler({
    required this.ownerNotifier,
    required this.permissionService,
  });

  /// Helper method to check if user has permission.
  /// Returns error map if permission denied, null if granted.
  Future<Map<String, dynamic>?> checkPermission(String permission) async {
    debugPrint('[ActionHandler] Checking permission: $permission');
    final hasPermission = await permissionService.hasPermission(
      permission,
      clinicId: ownerNotifier.clinicId,
    );
    debugPrint(
        '[ActionHandler] Permission "$permission" granted: $hasPermission');

    if (!hasPermission) {
      return {
        'error':
            'Permission denied: You do not have permission to perform this action. '
                'Contact your clinic administrator if you need access.'
      };
    }

    return null; // Permission granted
  }
}
