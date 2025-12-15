import 'package:equatable/equatable.dart';

abstract class GoogleDriveEvent extends Equatable {
  const GoogleDriveEvent();

  @override
  List<Object> get props => [];
}

class AuthenticateGoogleDrive extends GoogleDriveEvent {}

class SearchGoogleDrive extends GoogleDriveEvent {
  final String query;
  final String? parentFolderId;
  final String? clinicFolderId;
  final List<String>? folderStack;

  const SearchGoogleDrive({
    this.query = '',
    this.parentFolderId,
    this.clinicFolderId,
    this.folderStack,
  });

  @override
  List<Object> get props =>
      [query, parentFolderId ?? '', clinicFolderId ?? '', folderStack ?? []];
}

class GoToFolder extends GoogleDriveEvent {
  final String folderId;
  final String folderName;

  const GoToFolder(this.folderId, this.folderName);

  @override
  List<Object> get props => [folderId, folderName];
}

class GoBack extends GoogleDriveEvent {}

