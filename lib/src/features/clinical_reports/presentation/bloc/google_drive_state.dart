import 'package:equatable/equatable.dart';
import 'package:googleapis/drive/v3.dart' as drive;

abstract class GoogleDriveState extends Equatable {
  const GoogleDriveState();

  @override
  List<Object> get props => [];
}

class GoogleDriveInitial extends GoogleDriveState {}

class GoogleDriveAuthenticationRequired extends GoogleDriveState {
  const GoogleDriveAuthenticationRequired();
}

class GoogleDriveLoading extends GoogleDriveState {}

class GoogleDriveAuthenticated extends GoogleDriveState {
  final List<drive.File> files;
  final String? currentFolderId;
  final String? clinicFolderId;
  final List<String> folderStack; // To keep track of navigation history

  const GoogleDriveAuthenticated({
    required this.files,
    this.currentFolderId,
    this.clinicFolderId,
    this.folderStack = const [],
  });

  @override
  List<Object> get props =>
      [files, currentFolderId ?? '', clinicFolderId ?? '', folderStack];

  GoogleDriveAuthenticated copyWith({
    List<drive.File>? files,
    String? currentFolderId,
    String? clinicFolderId,
    List<String>? folderStack,
  }) {
    return GoogleDriveAuthenticated(
      files: files ?? this.files,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      clinicFolderId: clinicFolderId ?? this.clinicFolderId,
      folderStack: folderStack ?? this.folderStack,
    );
  }
}

class GoogleDriveError extends GoogleDriveState {
  final String message;

  const GoogleDriveError(this.message);

  @override
  List<Object> get props => [message];
}
