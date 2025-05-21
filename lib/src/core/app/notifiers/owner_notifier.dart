import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
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

  List<ClinicModel> _clinics = [];
  List<ClinicModel> get clinics => _clinics;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> loadOwnerIdAndClinicId() async {
    _loading = true;
    notifyListeners();
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[OwnerNotifier] Current user: \\${user?.uid}');
    if (user == null) {
      debugPrint('[OwnerNotifier] No user logged in.');
      _ownerId = null;
      _clinicId = null;
      _loading = false;
      notifyListeners();
      return;
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    debugPrint('[OwnerNotifier] User doc data: \\$data');
    _ownerId = data?['ownerId'] ?? user.uid;
    debugPrint('[OwnerNotifier] Loaded ownerId: \\$_ownerId');
    // Prefer primaryClinicId, fallback to first clinicIds entry, else null
    if (data?['primaryClinicId'] != null &&
        data?['primaryClinicId'] is String) {
      _clinicId = data?['primaryClinicId'];
      debugPrint('[OwnerNotifier] Loaded primaryClinicId: \\$_clinicId');
    } else if (data?['clinicIds'] is List &&
        (data?['clinicIds'] as List).isNotEmpty) {
      _clinicId = (data?['clinicIds'] as List).first;
      debugPrint('[OwnerNotifier] Loaded first clinicId from clinicIds: \\$_clinicId');
    } else {
      _clinicId = null;
      debugPrint('[OwnerNotifier] No clinicId found.');
    }

    // Fetch all clinics for this owner
    if (_ownerId != null) {
      debugPrint('[OwnerNotifier] Querying clinics for ownerId: \\$_ownerId');
      final clinicsSnap = await FirebaseFirestore.instance
          .collection('clinics')
          .where('ownerId', isEqualTo: _ownerId)
          .get();
      debugPrint('[OwnerNotifier] Clinics found: \\${clinicsSnap.docs.length}');
      _clinics = clinicsSnap.docs.map((doc) {
        final clinicData = doc.data();
        debugPrint('[OwnerNotifier] Clinic doc: id=\\${doc.id}, data=\\$clinicData');
        return ClinicModel.fromJson({
          'id': doc.id,
          ...clinicData,
        });
      }).toList();
    } else {
      debugPrint('[OwnerNotifier] ownerId is null, not querying clinics.');
      _clinics = [];
    }

    _loading = false;
    notifyListeners();
  }
}
