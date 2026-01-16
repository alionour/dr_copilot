import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/marker_type.dart';

class MarkerTypesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all built-in marker types
  List<MarkerType> getBuiltInTypes() {
    return MarkerType.builtInTypes;
  }

  /// Get custom marker types for a specific clinic
  Future<List<MarkerType>> getCustomTypes(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('marker_types')
          .get();

      return snapshot.docs
          .map((doc) => MarkerType.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load custom marker types: $e');
    }
  }

  /// Get all marker types (built-in + custom) for a clinic
  Future<List<MarkerType>> getAllTypes(String clinicId) async {
    final builtIn = getBuiltInTypes();
    final custom = await getCustomTypes(clinicId);
    return [...builtIn, ...custom];
  }

  /// Save a new custom marker type
  Future<void> saveCustomType(String clinicId, MarkerType markerType) async {
    try {
      final data = markerType.toJson();
      data.remove('id'); // Firestore will generate ID
      data['isBuiltIn'] = false; // Always false for custom types

      await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('marker_types')
          .add(data);
    } catch (e) {
      throw Exception('Failed to save marker type: $e');
    }
  }

  /// Update an existing custom marker type
  Future<void> updateCustomType(
    String clinicId,
    String typeId,
    MarkerType markerType,
  ) async {
    try {
      final data = markerType.toJson();
      data.remove('id');
      data['isBuiltIn'] = false;

      await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('marker_types')
          .doc(typeId)
          .update(data);
    } catch (e) {
      throw Exception('Failed to update marker type: $e');
    }
  }

  /// Delete a custom marker type
  Future<void> deleteCustomType(String clinicId, String typeId) async {
    try {
      await _firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('marker_types')
          .doc(typeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete marker type: $e');
    }
  }

  /// Check if a marker type name already exists for this clinic
  Future<bool> typeNameExists(String clinicId, String name,
      {String? excludeId}) async {
    // Check built-in types
    final builtIn = getBuiltInTypes();
    if (builtIn.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
      return true;
    }

    // Check custom types
    final custom = await getCustomTypes(clinicId);
    return custom.any(
      (t) => t.name.toLowerCase() == name.toLowerCase() && t.id != excludeId,
    );
  }
}
