import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class OwnerNotifier with ChangeNotifier {
  static final OwnerNotifier _instance = OwnerNotifier._internal();
  factory OwnerNotifier() => _instance;
  OwnerNotifier._internal();

  String? _ownerId;
  String? get ownerId => _ownerId;

  String? _clinicId;
  String? get clinicId => _clinicId;

  AppRole? _role;
  AppRole? get role => _role;

  List<ClinicModel> _clinics = [];
  List<ClinicModel> get clinics => _clinics;

  bool _loading = false;
  bool get loading => _loading;

  /// Delegate permission checks to PermissionService
  bool hasPermission(AppPermission permission) {
    return GetIt.I<PermissionService>().hasPermissionSync(
      permission,
      clinicId: _clinicId,
    );
  }

  void clear() {
    _ownerId = null;
    _clinicId = null;
    _role = null;
    _clinics = [];
    // Clear permission cache in service
    GetIt.I<PermissionService>().clearCache();
    notifyListeners();
  }

  Future<void> loadOwnerIdAndClinicId() async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[OwnerNotifier] 🔄 loadOwnerIdAndClinicId() CALLED');
    debugPrint('═══════════════════════════════════════════════════');
    _loading = true;
    notifyListeners();

    try {
      final userResult =
          await GetIt.I<AbstractAuthRepository>().getCurrentUser();

      final user = userResult.fold(
        (failure) {
          debugPrint(
              '[OwnerNotifier] ❌ Error getting current user: ${failure.message}');
          return null;
        },
        (user) => user,
      );

      debugPrint('[OwnerNotifier] Current user: ${user?.uid}');
      if (user == null) {
        debugPrint('[OwnerNotifier] ❌ No user logged in.');
        _ownerId = null;
        _clinicId = null;
        _role = null;
        _loading = false;
        notifyListeners();
        return;
      }

      // CRITICAL: Set ownerId IMMEDIATELY from user UID
      // This ensures queries work even if subsequent Firestore calls fail
      _ownerId = user.uid;
      debugPrint('[OwnerNotifier] Set ownerId from user: $_ownerId');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = userDoc.data();
      debugPrint('[OwnerNotifier] User doc data: $data');

      // Update ownerId if explicitly set in Firestore, otherwise keep user.uid
      if (data?['ownerId'] != null) {
        _ownerId = data!['ownerId'];
        debugPrint('[OwnerNotifier] Updated ownerId from Firestore: $_ownerId');
      }
      // Prefer primaryClinicId, fallback to first clinicIds entry, else null
      if (data?['primaryClinicId'] != null &&
          data?['primaryClinicId'] is String) {
        _clinicId = data?['primaryClinicId'];
        debugPrint('[OwnerNotifier] Loaded primaryClinicId: $_clinicId');
      } else if (data?['clinicIds'] is List &&
          (data?['clinicIds'] as List).isNotEmpty) {
        _clinicId = (data?['clinicIds'] as List).first;
        debugPrint(
          '[OwnerNotifier] Loaded first clinicId from clinicIds: $_clinicId',
        );
      } else {
        _clinicId = null;
        debugPrint('[OwnerNotifier] No clinicId found.');
      }

      // Load Role from clinic members subcollection
      if (_clinicId != null) {
        debugPrint(
          '[OwnerNotifier] Fetching role from clinics/$_clinicId/members/${user.uid}',
        );
        try {
          final memberDoc = await FirebaseFirestore.instance
              .collection('clinics')
              .doc(_clinicId)
              .collection('members')
              .doc(user.uid)
              .get();

          if (memberDoc.exists) {
            final memberData = memberDoc.data();

            // Parse Role
            if (memberData?['role'] != null) {
              final roleStr = memberData!['role'] as String;
              _role = AppRole.values.firstWhere(
                (e) => e.name.toLowerCase() == roleStr.toLowerCase(),
                orElse: () => AppRole.readonly,
              );
              debugPrint('[OwnerNotifier] Loaded role: $_role');
            }

            // Start real-time permission listener
            debugPrint(
                '[OwnerNotifier] Initializing PermissionService listener');
            await GetIt.I<PermissionService>().initialize(
              user.uid,
              clinicId: _clinicId,
            );
          } else {
            debugPrint(
              '[OwnerNotifier] ❌ Member document not found for user in clinic $_clinicId',
            );
            _role = null;
          }
        } catch (e) {
          debugPrint('[OwnerNotifier] ❌ Error fetching member data: $e');
          _role = null;
        }
      }

      // Fetch all clinics for this user based on clinicIds AND ownerId
      Set<ClinicModel> allClinics = {};
      Set<String> targetClinicIds = {};

      // 1. Extract IDs from 'clinicIds' field (if present)
      if (data?['clinicIds'] is List) {
        targetClinicIds.addAll(List<String>.from(data?['clinicIds']));
      }

      // 2. Extract IDs from 'clinics' array (rich object)
      if (data?['clinics'] is List) {
        for (var c in data!['clinics']) {
          if (c is Map && c['clinicId'] is String) {
            targetClinicIds.add(c['clinicId']);
          }
        }
      }

      debugPrint(
        '[OwnerNotifier] Consolidated clinic IDs to fetch: $targetClinicIds',
      );

      // 3. Fetch by collected IDs
      if (targetClinicIds.isNotEmpty) {
        final clinicIdsList = targetClinicIds.toList();

        // Split into chunks of 10
        for (var i = 0; i < clinicIdsList.length; i += 10) {
          final end =
              (i + 10 < clinicIdsList.length) ? i + 10 : clinicIdsList.length;
          final chunk = clinicIdsList.sublist(i, end);

          try {
            debugPrint('[OwnerNotifier] Querying clinics with IDs: $chunk');
            final clinicsSnap = await FirebaseFirestore.instance
                .collection('clinics')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

            debugPrint(
              '[OwnerNotifier] Found ${clinicsSnap.docs.length} clinics in this chunk',
            );
            for (var doc in clinicsSnap.docs) {
              final clinicData = doc.data();
              debugPrint(
                '[OwnerNotifier]   - Clinic: ${doc.id} -> ${clinicData['name']}',
              );
              allClinics
                  .add(ClinicModel.fromJson({'id': doc.id, ...clinicData}));
            }
          } catch (e) {
            debugPrint('[OwnerNotifier] ❌ Error fetching clinics chunk: $e');
          }
        }
      }

      // NOTE: Removed ownerId query - security rules don't allow querying clinics by ownerId
      // Clinics are already loaded from clinicIds/userClinics array above
      // If we need owner-specific clinics, they should be in the user's clinicIds field

      // Deduplicate by ID
      final Map<String, ClinicModel> uniqueClinics = {
        for (var c in allClinics) c.id: c,
      };

      _clinics = uniqueClinics.values.toList();
      debugPrint(
        '[OwnerNotifier] ✅ Total unique clinics loaded: ${_clinics.length}',
      );
      for (var clinic in _clinics) {
        debugPrint('[OwnerNotifier]    - ${clinic.id}: ${clinic.name}');
      }
      debugPrint('═══════════════════════════════════════════════════');
    } catch (e) {
      debugPrint('[OwnerNotifier] ❌ Fatal error in loadOwnerIdAndClinicId: $e');
      // Set minimal defaults to allow app to continue
      _role = null;
      _clinics = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
