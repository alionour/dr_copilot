import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
      : super(const NavigationState(null, Destination.copilot, true)) {
    on<NavigateToEvent>(navigateTo);
    on<GetUserData>(getUserData);
    on<NavigateUpEvent>(navigateUp);
    on<NavigateDownEvent>(navigateDown);
    on<ChangeFocusEvent>(changeFocus);
    add(GetUserData());
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
      case Destination.notifications:
        emit(state.copyWith(destination: Destination.notifications));
        break;
      case Destination.settings:
        emit(state.copyWith(destination: Destination.settings));
        break;
      case Destination.patients:
        emit(state.copyWith(destination: Destination.patients));
        break;
      case Destination.sessions:
        emit(state.copyWith(destination: Destination.sessions));
        break;
      case Destination.evaluations:
        emit(state.copyWith(destination: Destination.evaluations));
            case Destination.charts:
        emit(state.copyWith(destination: Destination.charts));
        break;
    }
  }

  void navigateUp(NavigateUpEvent event, Emitter emit) {
    final newIndex = (state.selectedIndex - 1 + Destination.values.length) %
        Destination.values.length;
    emit(state.copyWith(
        selectedIndex: newIndex, destination: Destination.values[newIndex]));
  }

  void navigateDown(NavigateDownEvent event, Emitter emit) {
    final newIndex = (state.selectedIndex + 1) % Destination.values.length;
    emit(state.copyWith(
        selectedIndex: newIndex, destination: Destination.values[newIndex]));
  }

  void changeFocus(ChangeFocusEvent event, Emitter emit) {
    emit(state.copyWith(isNavigationFocused: event.isFocused));
  }

  /// Fetch user data from Firebase
  void getUserData(GetUserData event, Emitter emit) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      emit(state.copyWith(user: user));
    } catch (error) {
      emit(state.copyWith(user: null));
    }
  }
}
