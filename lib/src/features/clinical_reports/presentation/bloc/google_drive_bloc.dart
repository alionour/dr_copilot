
import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/core/services/google_drive_service.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'google_drive_event.dart';
import 'google_drive_state.dart';

class GoogleDriveBloc extends Bloc<GoogleDriveEvent, GoogleDriveState> {
  final GoogleDriveService _googleDriveService;
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();
  final OwnerNotifier _ownerNotifier;

  GoogleDriveBloc(this._googleDriveService, this._ownerNotifier) : super(GoogleDriveInitial()) {
    on<AuthenticateGoogleDrive>((event, emit) async {
      debugPrint('AuthenticateGoogleDrive event received.');
      emit(GoogleDriveLoading());
      try {
        Client? client = await _googleSignInHelper.client;
        if (client == null) {
          final account = await _googleSignInHelper.signIn();
          if (account != null) {
            client = await _googleSignInHelper.client;
          }
        }

        if (client == null) {
          emit(const GoogleDriveAuthenticationRequired());
        } else {
          final clinicId = _ownerNotifier.clinicId;
          if (clinicId == null) {
            emit(const GoogleDriveError('Clinic ID not found. Cannot search for clinic folder.'));
            return;
          }
          final clinic = _ownerNotifier.clinics.firstWhereOrNull((c) => c.id == clinicId);
          final clinicName = clinic?.name;
          if (clinicName == null) {
            emit(const GoogleDriveError('Clinic name not found for the current clinic ID. Cannot search for clinic folder.'));
            return;
          }

          final clinicFolders = await _googleDriveService.searchFiles(
            query: clinicName,
            mimeType: 'application/vnd.google-apps.folder',
          );

          String? clinicFolderId;
          if (clinicFolders.isNotEmpty) {
            clinicFolderId = clinicFolders.first.id;
          }

          add(SearchGoogleDrive(query: '', parentFolderId: clinicFolderId, clinicFolderId: clinicFolderId));
        }
      } catch (e) {
        debugPrint('Error during AuthenticateGoogleDrive: $e');
        emit(GoogleDriveError(e.toString()));
      }
    });

    on<SearchGoogleDrive>((event, emit) async {
      debugPrint('SearchGoogleDrive event received with query: ${event.query}, parentFolderId: ${event.parentFolderId}');
      emit(GoogleDriveLoading());
      try {
        final files = await _googleDriveService.searchFiles(
          query: event.query,
          parentFolderId: event.parentFolderId,
        );
        debugPrint('Files found: ${files.length}');
        emit(GoogleDriveAuthenticated(
          files: files,
          currentFolderId: event.parentFolderId,
          clinicFolderId: event.clinicFolderId,
          folderStack: event.folderStack ?? [],
        ));
      } catch (e) {
        debugPrint('Error during SearchGoogleDrive: $e');
        emit(GoogleDriveError(e.toString()));
      }
    });

    on<GoToFolder>((event, emit) async {
      if (state is GoogleDriveAuthenticated) {
        final currentState = state as GoogleDriveAuthenticated;
        final newFolderStack = List<String>.from(currentState.folderStack)..add(currentState.currentFolderId ?? '');
        add(SearchGoogleDrive(
          parentFolderId: event.folderId,
          query: '',
          clinicFolderId: currentState.clinicFolderId,
          folderStack: newFolderStack,
        ));
      }
    });

    on<GoBack>((event, emit) async {
      if (state is GoogleDriveAuthenticated) {
        final currentState = state as GoogleDriveAuthenticated;
        if (currentState.folderStack.isNotEmpty) {
          final newFolderStack = List<String>.from(currentState.folderStack);
          final previousFolderId = newFolderStack.removeLast();
          add(SearchGoogleDrive(
            parentFolderId: previousFolderId.isEmpty ? null : previousFolderId,
            query: '',
            clinicFolderId: currentState.clinicFolderId,
            folderStack: newFolderStack,
          ));
        } else {
          // If stack is empty, go back to the clinic root or initial state
          add(SearchGoogleDrive(
            parentFolderId: currentState.clinicFolderId,
            query: '',
            clinicFolderId: currentState.clinicFolderId,
            folderStack: [],
          ));
        }
      }
    });
  }
}
