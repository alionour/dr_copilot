import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/services/user_discovery_service.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../data/repositories/direct_messages_repository.dart';

// States
abstract class UserDiscoveryState extends Equatable {
  const UserDiscoveryState();
  @override
  List<Object?> get props => [];
}

class UserDiscoveryInitial extends UserDiscoveryState {}

class UserDiscoveryLoading extends UserDiscoveryState {}

class UserDiscoveryLoaded extends UserDiscoveryState {
  final List<UserModel> users;
  const UserDiscoveryLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class UserDiscoveryError extends UserDiscoveryState {
  final String message;
  const UserDiscoveryError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatStarting extends UserDiscoveryState {}

class ChatStarted extends UserDiscoveryState {
  final String conversationId;
  const ChatStarted(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

// Cubit
class UserDiscoveryCubit extends Cubit<UserDiscoveryState> {
  final UserDiscoveryService _service;
  final DirectMessagesRepository _directMessagesRepository;

  UserDiscoveryCubit(this._service, this._directMessagesRepository)
    : super(UserDiscoveryInitial());

  Future<void> loadClinicMembers(String clinicId, String currentUserId) async {
    emit(UserDiscoveryLoading());
    try {
      final users = await _service.getClinicMembers(clinicId, currentUserId);
      // No need to filter out current user - service already does this
      emit(UserDiscoveryLoaded(users));
    } catch (e) {
      emit(UserDiscoveryError(e.toString()));
    }
  }

  Future<void> startChat(
    String clinicId,
    String currentUserId,
    String targetUserId,
  ) async {
    emit(ChatStarting());
    try {
      final conversationId = await _directMessagesRepository.startDirectChat(
        clinicId: clinicId,
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );
      emit(ChatStarted(conversationId));
    } catch (e) {
      emit(UserDiscoveryError("Failed to start chat: $e"));
    }
  }
}

