import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/navigation_side/domain/entities/destination.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
      : super(
          const NavigationState(
            null,
            Destination.copilot,
            true,
            allowedDestinations: {},
          ),
        ) {
    on<NavigateToEvent>(navigateTo);
    on<NavigateUpEvent>(navigateUp);
    on<NavigateDownEvent>(navigateDown);
    on<ChangeFocusEvent>(changeFocus);
    on<UserChanged>(_onUserChanged);
    on<DestinationsUpdated>(_onDestinationsUpdated);
  }

  void _onDestinationsUpdated(
    DestinationsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(allowedDestinations: event.destinations));
  }

  void _onUserChanged(UserChanged event, Emitter<NavigationState> emit) {
    emit(state.copyWith(user: Value(event.user)));
  }

  void navigateTo(NavigateToEvent event, Emitter emit) {
    switch (event.destination) {
      case Destination.copilot:
        emit(state.copyWith(destination: Destination.copilot));
        break;
      case Destination.calendar:
        emit(state.copyWith(destination: Destination.calendar));
        break;
      case Destination.chat:
        emit(state.copyWith(destination: Destination.chat));
        break;
      case Destination.liveAssistant:
        emit(state.copyWith(destination: Destination.liveAssistant));
        break;
      case Destination.notifications:
        emit(state.copyWith(destination: Destination.notifications));
        break;
      case Destination.settings:
        emit(state.copyWith(destination: Destination.settings));
        break;
      case Destination.patients:
        emit(state.copyWith(destination: Destination.patients));
        break;
      case Destination.doctors:
        emit(state.copyWith(destination: Destination.doctors));
        break;
      case Destination.staff:
        emit(state.copyWith(destination: Destination.staff));
        break;
      case Destination.invitations:
        emit(state.copyWith(destination: Destination.invitations));
        break;
      case Destination.sessions:
        emit(state.copyWith(destination: Destination.sessions));
        break;
      case Destination.evaluations:
        emit(state.copyWith(destination: Destination.evaluations));
        break;
      case Destination.charts:
        emit(state.copyWith(destination: Destination.charts));
        break;
      case Destination.financials:
        emit(state.copyWith(destination: Destination.financials));
        break;
      case Destination.clinicalReports:
        emit(state.copyWith(destination: Destination.clinicalReports));
        break;
      case Destination.chatGptProject:
        emit(state.copyWith(destination: Destination.chatGptProject));
        break;
      case Destination.teamChat:
        emit(state.copyWith(destination: Destination.teamChat));
        break;
      case Destination.teams:
        emit(state.copyWith(destination: Destination.teams));
        break;
      case Destination.recycleBin:
        emit(state.copyWith(destination: Destination.recycleBin));
        break;
      case Destination.inventory:
        emit(state.copyWith(destination: Destination.inventory));
        break;
      case Destination.departments:
        emit(state.copyWith(destination: Destination.departments));
        break;
      case Destination.tasks:
        emit(state.copyWith(destination: Destination.tasks));
        break;
    }
  }

  void navigateUp(NavigateUpEvent event, Emitter emit) {
    final newIndex = (state.selectedIndex - 1 + Destination.values.length) %
        Destination.values.length;
    emit(
      state.copyWith(
        selectedIndex: newIndex,
        destination: Destination.values[newIndex],
      ),
    );
  }

  void navigateDown(NavigateDownEvent event, Emitter emit) {
    final newIndex = (state.selectedIndex + 1) % Destination.values.length;
    emit(
      state.copyWith(
        selectedIndex: newIndex,
        destination: Destination.values[newIndex],
      ),
    );
  }

  void changeFocus(ChangeFocusEvent event, Emitter emit) {
    emit(state.copyWith(isNavigationFocused: event.isFocused));
  }
}
