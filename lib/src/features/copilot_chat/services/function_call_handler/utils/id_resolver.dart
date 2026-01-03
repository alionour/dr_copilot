import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';

class AmbiguousMatchException implements Exception {
  final int count;
  final String name;
  AmbiguousMatchException(this.name, this.count);
  @override
  String toString() => 'Found $count matches for "$name"';
}

/// Utility class for resolving entity names to their actual IDs
class IdResolver {
  /// Checks if a string is a valid UUID-like ID
  /// Returns false if it looks like a name instead
  static bool isValidId(String id) {
    // Check if it's a UUID pattern (loose check)
    // UUIDs are typically: 8-4-4-4-12 hex chars
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    // Also accept Firestore auto-generated IDs (20 alphanumeric chars)
    final firestorePattern = RegExp(r'^[a-zA-Z0-9]{20,}$');

    return uuidPattern.hasMatch(id) || firestorePattern.hasMatch(id);
  }

  /// Resolves a patient name to their ID
  /// Returns the ID if found, null if not found, or the original if already valid
  static Future<String?> resolvePatientId(
    String nameOrId,
    AbstractPatientsRepository patientRepo,
  ) async {
    // If it's already a valid ID, return it
    if (isValidId(nameOrId)) {
      return nameOrId;
    }

    // Otherwise, treat it as a name and search
    try {
      // Use getAllPatients() + client-side filtering to match the 'list_patients' behavior
      // (Case-insensitive 'contains' search)
      final result = await patientRepo.getAllPatients();
      return result.fold(
        (failure) => null, // Repo failure
        (patients) {
          final matches = patients.where((p) {
            return p.name.toLowerCase().contains(nameOrId.toLowerCase());
          }).toList();

          if (matches.isEmpty) return null;

          if (matches.length > 1) {
            throw AmbiguousMatchException(nameOrId, matches.length);
          }

          // Use the first match.
          return matches.first.id;
        },
      );
    } catch (e) {
      if (e is AmbiguousMatchException) rethrow;
      return null;
    }
  }
}
