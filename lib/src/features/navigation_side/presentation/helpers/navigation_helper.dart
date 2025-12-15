import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/navigation_side/domain/entities/destination.dart';

class NavigationHelper {
  static Future<Map<String, List<Destination>>> getAllowedDestinations(
    UserModel? user,
    String? clinicId,
  ) async {
    if (user == null || clinicId == null) {
      return {};
    }

    final role = await user.getRoleInClinic(clinicId);
    if (role == null) {
      return {};
    }

    final roleLower = role.toLowerCase();

    final allDestinations = {
      'coreOperations': [Destination.copilot, Destination.calendar],
      'management': [
        Destination.patients,
        Destination.doctors,
        Destination.staff,
        Destination.invitations,
        Destination.clinicalReports,
      ],
      'appointments': [Destination.sessions, Destination.evaluations],
      'business': [Destination.financials],
      'utilities': [
        Destination.notifications,
        Destination.settings,
        Destination.teamChat,
        Destination.teams,
        Destination.recycleBin,
      ],
    };

    final allowed = <String, List<Destination>>{};

    for (var entry in allDestinations.entries) {
      final category = entry.key;
      final destinations = entry.value;
      final allowedInCategory = <Destination>[];

      for (var dest in destinations) {
        switch (dest) {
          // Admin only
          case Destination.doctors:
          case Destination.staff:
          case Destination.invitations:
          case Destination.financials:
            if (roleLower == 'admin') {
              allowedInCategory.add(dest);
            }
            break;

          // Admin and Doctor
          case Destination.sessions:
          case Destination.evaluations:
          case Destination.clinicalReports:
            if (roleLower == 'admin' || roleLower == 'doctor') {
              allowedInCategory.add(dest);
            }
            break;

          // Admin, Doctor, and Staff
          case Destination.patients:
            if (roleLower == 'admin' ||
                roleLower == 'doctor' ||
                roleLower == 'staff') {
              allowedInCategory.add(dest);
            }
            break;

          // All roles
          case Destination.copilot:
          case Destination.calendar:
          case Destination.settings:
          case Destination.notifications:
          case Destination.teamChat:
          case Destination.teams:
          case Destination.recycleBin:
            allowedInCategory.add(dest);
            break;

          // These are not in the main UI, but let's handle them just in case
          case Destination.chat:
          case Destination.liveAssistant:
          case Destination.charts:
          case Destination.chatGptProject:
            // For now, only admin can see these if they are ever added back
            if (roleLower == 'admin') {
              allowedInCategory.add(dest);
            }
            break;
        }
      }

      if (allowedInCategory.isNotEmpty) {
        allowed[category] = allowedInCategory;
      }
    }

    return allowed;
  }
}

