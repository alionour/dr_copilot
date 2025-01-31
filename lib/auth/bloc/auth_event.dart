part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}



class SignInWithGoogle extends AuthEvent {
  @override
  List<Object> get props => [];
}

