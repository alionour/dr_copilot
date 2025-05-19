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
    if (user == null) {
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
    _ownerId = data?['ownerId'] ?? user.uid;
    // Prefer primaryClinicId, fallback to first clinicIds entry, else null
    if (data?['primaryClinicId'] != null &&
        data?['primaryClinicId'] is String) {
      _clinicId = data?['primaryClinicId'];
    } else if (data?['clinicIds'] is List &&
        (data?['clinicIds'] as List).isNotEmpty) {
      _clinicId = (data?['clinicIds'] as List).first;
    } else {
      _clinicId = null;
    }

    // Fetch all clinics for this owner
    if (_ownerId != null) {
      final clinicsSnap = await FirebaseFirestore.instance
          .collection('clinics')
          .where('ownerId', isEqualTo: _ownerId)
          .get();
      _clinics = clinicsSnap.docs.map((doc) {
        final clinicData = doc.data();
        return ClinicModel.fromJson({
          'id': doc.id,
          ...clinicData,
        });
      }).toList();
    } else {
      _clinics = [];
    }

    _loading = false;
    notifyListeners();
  }
}
