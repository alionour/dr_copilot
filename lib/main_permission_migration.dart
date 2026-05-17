import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/firebase_options.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_defaults.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MigrationApp());
}

class MigrationApp extends StatelessWidget {
  const MigrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Permission Migration Tool')),
        body: const MigrationRunner(),
      ),
    );
  }
}

class MigrationRunner extends StatefulWidget {
  const MigrationRunner({super.key});

  @override
  State<MigrationRunner> createState() => _MigrationRunnerState();
}

class _MigrationRunnerState extends State<MigrationRunner> {
  String _status = 'Ready to migrate permissions.';
  bool _isLoading = false;

  // Dynamically load permissions from RoleDefaults
  List<String> get _allPermissions => RoleDefaults.getPermissionsForRole(AppRole.admin)
      .map((e) => e.name)
      .toList();

  List<String> get _doctorPermissions => RoleDefaults.getPermissionsForRole(AppRole.doctor)
      .map((e) => e.name)
      .toList();

  List<String> get _staffPermissions => RoleDefaults.getPermissionsForRole(AppRole.staff)
      .map((e) => e.name)
      .toList();

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting migration...';
    });

    try {
      final firestore = FirebaseFirestore.instance;
      int ownersUpdated = 0;
      int membersUpdated = 0;

      // 1. Update Users (Global Owners)
      _status = 'Updating Owners (users collection)...';
      final usersSnapshot = await firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        // Global owners always get ALL permissions
        bool changed = await _updateDocumentPermissions(
            doc.reference, doc.data(), _allPermissions);
        if (changed) ownersUpdated++;
      }

      // 2. Update Clinic Members (Doctors, Staff, etc.)
      _status = 'Updating Clinic Members...';
      final clinicsSnapshot = await firestore.collection('clinics').get();

      for (var clinicDoc in clinicsSnapshot.docs) {
        final membersSnapshot =
            await clinicDoc.reference.collection('members').get();

        for (var memberDoc in membersSnapshot.docs) {
          final data = memberDoc.data();
          final role = (data['role'] as String?)?.toLowerCase() ?? '';

          List<String> targetPermissions = [];

          if (role == 'admin' || role == 'owner') {
            targetPermissions = _allPermissions;
          } else if (role == 'doctor') {
            targetPermissions = _doctorPermissions;
          } else if (role == 'staff' ||
              role == 'nurse' ||
              role == 'secretary') {
            targetPermissions = _staffPermissions;
          } else {
            // Unknown role? Skip or give basic view?
            continue;
          }

          bool changed = await _updateDocumentPermissions(
              memberDoc.reference, data, targetPermissions);
          if (changed) membersUpdated++;
        }
      }

      _status =
          'Migration Complete!\nUpdated $ownersUpdated Owners in users collection.\nUpdated $membersUpdated Clinic Members.';
    } catch (e) {
      _status = 'Error: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _updateDocumentPermissions(DocumentReference ref,
      Map<String, dynamic> data, List<String> permissionsToAdd) async {
    List<dynamic> currentPermissions = data['permissions'] ?? [];
    List<String> newPermissions = List.from(currentPermissions);
    bool changed = false;

    for (var perm in permissionsToAdd) {
      if (!newPermissions.contains(perm)) {
        newPermissions.add(perm);
        changed = true;
      }
    }

    if (changed) {
      await ref.update({'permissions': newPermissions});
    }
    return changed;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _runMigration,
              child: const Text('Run Migration'),
            ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'This tool will:\n1. Grant ALL current permissions to Admins/Owners.\n2. Grant DOCTOR permissions to members with role "doctor".\n3. Grant STAFF permissions to members with role "staff/nurse/secretary".',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
