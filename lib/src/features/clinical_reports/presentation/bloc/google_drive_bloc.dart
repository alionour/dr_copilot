import 'package:http/http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/core/services/google_drive_service.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'package:universal_io/io.dart' as io;
import 'google_drive_event.dart';
import 'google_drive_state.dart';

class GoogleDriveBloc extends Bloc<GoogleDriveEvent, GoogleDriveState> {
  final GoogleDriveService _googleDriveService;
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();
  final OwnerNotifier _ownerNotifier;

  GoogleDriveBloc(this._googleDriveService, this._ownerNotifier)
      : super(GoogleDriveInitial()) {
    on<CheckAuthStatus>((event, emit) async {
      debugPrint('CheckAuthStatus event received.');
      emit(GoogleDriveLoading());
      try {
        // First, try to get existing authenticated client
        Client? client = await _googleSignInHelper.client;

        if (client == null) {
          // No existing client, try to initialize one silently
          debugPrint(
              'No existing client found. Attempting to initialize silently...');
          client = await _googleSignInHelper.ensureClientInitialized();

          // If still null, try to restore from storage on Desktop
          if (client == null &&
              (io.Platform.isWindows || io.Platform.isLinux)) {
            debugPrint(
                'Desktop platform detected. Attempting to restore client from storage...');
            client = await _googleSignInHelper.restoreClientFromStorage();
          }
        }

        if (client == null) {
          debugPrint(
            'Silent authentication failed. Emitting GoogleDriveAuthenticationRequired.',
          );
          emit(const GoogleDriveAuthenticationRequired());
        } else {
          // Proceed to load content (same as AuthenticateGoogleDrive)
          final clinicId = _ownerNotifier.clinicId;
          if (clinicId == null) {
            emit(
              const GoogleDriveError(
                'Clinic ID not found. Cannot search for clinic folder.',
              ),
            );
            return;
          }
          final clinic = _ownerNotifier.clinics.firstWhereOrNull(
            (c) => c.id == clinicId,
          );
          final clinicName = clinic?.name;
          if (clinicName == null) {
            emit(
              const GoogleDriveError(
                'Clinic name not found for the current clinic ID. Cannot search for clinic folder.',
              ),
            );
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

          add(
            SearchGoogleDrive(
              query: '',
              parentFolderId: clinicFolderId,
              clinicFolderId: clinicFolderId,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error during CheckAuthStatus: $e');
        emit(GoogleDriveError(e.toString()));
      }
    });

    on<AuthenticateGoogleDrive>((event, emit) async {
      debugPrint('AuthenticateGoogleDrive event received.');
      emit(GoogleDriveLoading());
      try {
        // First, try to get existing authenticated client
        Client? client = await _googleSignInHelper.client;

        if (client == null) {
          // No existing client, try to initialize one
          debugPrint('No existing client found. Attempting to initialize...');
          client = await _googleSignInHelper.ensureClientInitialized();

          // If still null after ensureClientInitialized, check platform
          if (client == null) {
            debugPrint(
              'ensureClientInitialized returned null. Checking platform...',
            );

            // For desktop platforms, use the desktop OAuth flow
            if (io.Platform.isWindows || io.Platform.isLinux) {
              debugPrint(
                'Desktop platform detected. Using signInAllPlatforms...',
              );
              final result = await _googleSignInHelper.signInAllPlatforms();
              if (result != null) {
                client = await _googleSignInHelper.client;
                debugPrint('Desktop sign-in successful. Client: $client');
              } else {
                debugPrint('Desktop sign-in failed or was cancelled.');
              }
            } else {
              // For mobile/web, the ensureClientInitialized already tried interactive sign-in
              debugPrint(
                'Mobile/Web platform. Interactive sign-in already attempted.',
              );
            }
          } else {
            debugPrint('Client initialized successfully from existing tokens.');
          }
        } else {
          debugPrint('Using existing authenticated client.');
        }

        if (client == null) {
          debugPrint(
            'Authentication failed or cancelled. Emitting GoogleDriveAuthenticationRequired.',
          );
          emit(const GoogleDriveAuthenticationRequired());
        } else {
          final clinicId = _ownerNotifier.clinicId;
          if (clinicId == null) {
            emit(
              const GoogleDriveError(
                'Clinic ID not found. Cannot search for clinic folder.',
              ),
            );
            return;
          }
          final clinic = _ownerNotifier.clinics.firstWhereOrNull(
            (c) => c.id == clinicId,
          );
          final clinicName = clinic?.name;
          if (clinicName == null) {
            emit(
              const GoogleDriveError(
                'Clinic name not found for the current clinic ID. Cannot search for clinic folder.',
              ),
            );
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

          add(
            SearchGoogleDrive(
              query: '',
              parentFolderId: clinicFolderId,
              clinicFolderId: clinicFolderId,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error during AuthenticateGoogleDrive: $e');
        emit(GoogleDriveError(e.toString()));
      }
    });

    on<SearchGoogleDrive>((event, emit) async {
      debugPrint(
        'SearchGoogleDrive event received with query: ${event.query}, parentFolderId: ${event.parentFolderId}',
      );
      emit(GoogleDriveLoading());
      try {
        final files = await _googleDriveService.searchFiles(
          query: event.query,
          parentFolderId: event.parentFolderId,
        );
        debugPrint('Files found: ${files.length}');
        emit(
          GoogleDriveAuthenticated(
            files: files,
            currentFolderId: event.parentFolderId,
            clinicFolderId: event.clinicFolderId,
            folderStack: event.folderStack ?? [],
          ),
        );
      } catch (e) {
        debugPrint('Error during SearchGoogleDrive: $e');
        emit(GoogleDriveError(e.toString()));
      }
    });

    on<GoToFolder>((event, emit) async {
      if (state is GoogleDriveAuthenticated) {
        final currentState = state as GoogleDriveAuthenticated;
        final newFolderStack = List<String>.from(currentState.folderStack)
          ..add(currentState.currentFolderId ?? '');
        add(
          SearchGoogleDrive(
            parentFolderId: event.folderId,
            query: '',
            clinicFolderId: currentState.clinicFolderId,
            folderStack: newFolderStack,
          ),
        );
      }
    });

    on<GoBack>((event, emit) async {
      if (state is GoogleDriveAuthenticated) {
        final currentState = state as GoogleDriveAuthenticated;
        if (currentState.folderStack.isNotEmpty) {
          final newFolderStack = List<String>.from(currentState.folderStack);
          final previousFolderId = newFolderStack.removeLast();
          add(
            SearchGoogleDrive(
              parentFolderId:
                  previousFolderId.isEmpty ? null : previousFolderId,
              query: '',
              clinicFolderId: currentState.clinicFolderId,
              folderStack: newFolderStack,
            ),
          );
        } else {
          // If stack is empty, go back to the clinic root or initial state
          add(
            SearchGoogleDrive(
              parentFolderId: currentState.clinicFolderId,
              query: '',
              clinicFolderId: currentState.clinicFolderId,
              folderStack: [],
            ),
          );
        }
      }
    });
  }
}
