import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/navigation_side/domain/entities/destination.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

class NavigationHelper {
  static Future<Map<String, List<Destination>>> getAllowedDestinations(
    UserModel? user,
    String? clinicId,
  ) async {
    if (user == null || clinicId == null) {
      return {};
    }

    final notifier = OwnerNotifier();
    
    // Ensure permissions are loaded if not already
    // (In practice, OwnerNotifier loads them during auth state changes)

    final allDestinations = {
      'coreOperations': [Destination.copilot, Destination.calendar],
      'management': [
        Destination.patients,
        Destination.doctors,
        Destination.departments,
        Destination.staff,
        Destination.invitations,
        Destination.clinicalReports,
        Destination.inventory,
        Destination.tasks,
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
        bool isAllowed = false;
        switch (dest) {
          case Destination.copilot:
            isAllowed = notifier.hasPermission(AppPermission.useCopilot);
            break;
          case Destination.calendar:
            isAllowed = notifier.hasPermission(AppPermission.viewCalendar);
            break;
          case Destination.patients:
            isAllowed = notifier.hasPermission(AppPermission.viewPatients);
            break;
          case Destination.doctors:
            isAllowed = notifier.hasPermission(AppPermission.viewDoctors) ||
                notifier.hasPermission(AppPermission.manageDoctors);
            break;
          case Destination.departments:
            isAllowed = notifier.hasPermission(AppPermission.viewDepartments) ||
                notifier.hasPermission(AppPermission.manageDepartments);
            break;
          case Destination.staff:
            isAllowed = notifier.hasPermission(AppPermission.manageStaff);
            break;
          case Destination.invitations:
            isAllowed = notifier.hasPermission(AppPermission.viewInvitations) ||
                notifier.hasPermission(AppPermission.sendInvitation);
            break;
          case Destination.clinicalReports:
            isAllowed = notifier.hasPermission(AppPermission.viewClinicalReports);
            break;
          case Destination.inventory:
            isAllowed = notifier.hasPermission(AppPermission.viewInventory);
            break;
          case Destination.tasks:
            isAllowed = notifier.hasPermission(AppPermission.viewAllTasks) ||
                notifier.hasPermission(AppPermission.viewOwnTasks) ||
                notifier.hasPermission(AppPermission.createTask) ||
                notifier.hasPermission(AppPermission.updateTask) ||
                notifier.hasPermission(AppPermission.deleteTask);
            break;
          case Destination.sessions:
            isAllowed = notifier.hasPermission(AppPermission.viewSessions);
            break;
          case Destination.evaluations:
            isAllowed = notifier.hasPermission(AppPermission.viewEvaluations);
            break;

          case Destination.financials:
            isAllowed = notifier.hasPermission(AppPermission.viewFinancials);
            break;
          case Destination.notifications:
            isAllowed = notifier.hasPermission(AppPermission.viewNotifications);
            break;
          case Destination.settings:
            isAllowed = true;
            break;
          case Destination.teamChat:
            isAllowed = notifier.hasPermission(AppPermission.viewTeamMessages) ||
                notifier.hasPermission(AppPermission.viewTeams) ||
                notifier.hasPermission(AppPermission.manageTeams) ||
                notifier.hasPermission(AppPermission.createTeam);
            break;
          case Destination.teams:
            isAllowed = notifier.hasPermission(AppPermission.viewTeams) ||
                notifier.hasPermission(AppPermission.manageTeams);
            break;
          case Destination.recycleBin:
            isAllowed = notifier.hasPermission(AppPermission.viewRecycleBin);
            break;
          default:
            isAllowed = false;
        }

        if (isAllowed) {
          allowedInCategory.add(dest);
        }
      }

      if (allowedInCategory.isNotEmpty) {
        allowed[category] = allowedInCategory;
      }
    }

    return allowed;
  }
}
