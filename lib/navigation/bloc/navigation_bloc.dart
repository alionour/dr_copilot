import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState(null,Destination.home)) {
    on<NavigateToEvent>(navigateTo);

    on<GetUserData>(getUserData);

    add(GetUserData());
  }

  void navigateTo(NavigateToEvent event, Emitter emit) {
    switch (event.destination) {
      case Destination.home:
        emit(state.copyWith(destination:Destination.home));
        break;
      case Destination.calendar:
                emit(state.copyWith(destination:Destination.calendar));
        break;
      case Destination.chat:
                emit(state.copyWith(destination:Destination.chat));

        break;
      case Destination.notifications:
                emit(state.copyWith(destination:Destination.notifications));

        break;
      case Destination.settings:
                emit(state.copyWith(destination:Destination.settings));

        break;
    }
  }

  /// fetch user data
  void getUserData(GetUserData event, Emitter emit) async {
    try {
      final response = await Supabase.instance.client.auth.getUser();
      emit(state.copyWith(user:response.user));
    } catch (error) {
      if (error is AuthException) {
        if (error.message.contains('token is expired')) {
          try {
            // Attempt to refresh the session
            final refreshResponse =
                await Supabase.instance.client.auth.refreshSession();
            if (refreshResponse.session != null) {
              // Get user details with new token
              final newResponse = await Supabase.instance.client.auth.getUser();
              emit(state.copyWith(user:newResponse.user));
            } else {
              // If refresh fails, log out the user
              await Supabase.instance.client.auth.signOut();
              emit(state.copyWith(user:null));
            }
          } catch (refreshError) {
            // Handle refresh failure
            await Supabase.instance.client.auth.signOut();
            emit( state.copyWith(user:null));
            
          }
        } else {
          // Handle other auth errors
          emit(state.copyWith(user:null));
        }
      }
    }
  }
}
