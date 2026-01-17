part of 'recycle_bin_bloc.dart';

abstract class RecycleBinEvent extends Equatable {
  const RecycleBinEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeletedItems extends RecycleBinEvent {}

class RestoreItem extends RecycleBinEvent {
  final String id;
  final RecycleBinItemType type;

  const RestoreItem({required this.id, required this.type});

  @override
  List<Object?> get props => [id, type];
}

class PermanentlyDeleteItem extends RecycleBinEvent {
  final String id;
  final RecycleBinItemType type;

  const PermanentlyDeleteItem({required this.id, required this.type});

  @override
  List<Object?> get props => [id, type];
}

enum RecycleBinItemType { evaluation, session, patient, calendarEvent }
