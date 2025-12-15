import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  List<AppPermission> _permissions = [];
  List<AppPermission> get permissions => _permissions;

  List<ClinicModel> _clinics = [];
  List<ClinicModel> get clinics => _clinics;

  bool _loading = false;
  bool get loading => _loading;

  bool hasPermission(AppPermission permission) {
    return _permissions.contains(permission);
  }

  Future<void> loadOwnerIdAndClinicId() async {
    debugPrint('═══════════════════════════════════════════════════');
    debugPrint('[OwnerNotifier] 🔄 loadOwnerIdAndClinicId() CALLED');
    debugPrint('═══════════════════════════════════════════════════');
    _loading = true;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[OwnerNotifier] Current user: ${user?.uid}');
    if (user == null) {
      debugPrint('[OwnerNotifier] ❌ No user logged in.');
      _ownerId = null;
      _clinicId = null;
      _role = null;
      _permissions = [];
      _loading = false;
      notifyListeners();
      return;
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    debugPrint('[OwnerNotifier] User doc data: $data');
    _ownerId = data?['ownerId'] ?? user.uid;
    debugPrint('[OwnerNotifier] Loaded ownerId: $_ownerId');
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

    // Load Role and Permissions from the clinic members subcollection (Single Source of Truth)
    if (_clinicId != null) {
      debugPrint(
        '[OwnerNotifier] Fetching permissions from clinics/$_clinicId/members/${user.uid}',
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

          // Parse Permissions
          if (memberData?['permissions'] != null) {
            final permsList = memberData!['permissions'] as List<dynamic>;
            _permissions = permsList.map((p) {
              return AppPermission.values.firstWhere(
                (e) => e.name == p,
                orElse: () => AppPermission.viewAllPatients, // Default fallback
              );
            }).toList();
            debugPrint(
              '[OwnerNotifier] Loaded ${_permissions.length} permissions',
            );
          } else {
            _permissions = [];
            debugPrint('[OwnerNotifier] No permissions field in member doc');
          }
        } else {
          debugPrint(
            '[OwnerNotifier] ❌ Member document not found for user in clinic $_clinicId',
          );
          // Fallback or clear permissions?
          // If member doc doesn't exist, they technically aren't a member or data is missing.
          _role = null;
          _permissions = [];
        }
      } catch (e) {
        debugPrint('[OwnerNotifier] ❌ Error fetching member permissions: $e');
        _role = null;
        _permissions = [];
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
        final end = (i + 10 < clinicIdsList.length)
            ? i + 10
            : clinicIdsList.length;
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
            allClinics.add(ClinicModel.fromJson({'id': doc.id, ...clinicData}));
          }
        } catch (e) {
          debugPrint('[OwnerNotifier] ❌ Error fetching clinics chunk: $e');
        }
      }
    }

    // 4. Fetch by ownerId (fallback/legacy)
    if (_ownerId != null) {
      debugPrint('[OwnerNotifier] Querying clinics for ownerId: $_ownerId');
      try {
        final clinicsSnap = await FirebaseFirestore.instance
            .collection('clinics')
            .where('ownerId', isEqualTo: _ownerId)
            .get();

        debugPrint(
          '[OwnerNotifier] Found ${clinicsSnap.docs.length} clinics by ownerId',
        );
        for (var doc in clinicsSnap.docs) {
          final clinicData = doc.data();
          debugPrint(
            '[OwnerNotifier]   - Clinic: ${doc.id} -> ${clinicData['name']}',
          );
          allClinics.add(ClinicModel.fromJson({'id': doc.id, ...clinicData}));
        }
      } catch (e) {
        debugPrint('[OwnerNotifier] ❌ Error fetching clinics by ownerId: $e');
      }
    }

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

    _loading = false;
    notifyListeners();
  }
}

