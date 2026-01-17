import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';

class GoogleDriveService {
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();

  Future<http.Client?> _getAuthClient() async {
    debugPrint(
        'Attempting to get authenticated client from GoogleSignInHelper...');
    final client = await _googleSignInHelper.client;
    if (client == null) {
      debugPrint('Authenticated client from GoogleSignInHelper is null.');
    }
    return client;
  }

  Future<drive.File?> getFile(String fileId) async {
    final client = await _getAuthClient();
    if (client == null) {
      return null;
    }

    final driveApi = drive.DriveApi(client);
    try {
      final file = await driveApi.files.get(
        fileId,
        $fields: 'id, name, mimeType, modifiedTime, webViewLink',
      ) as drive.File;
      return file;
    } catch (e) {
      debugPrint('Error calling Google Drive API files.get: $e');
      rethrow;
    }
  }

  Future<List<drive.File>> searchFiles(
      {String? query, String? parentFolderId, String? mimeType}) async {
    final client = await _getAuthClient();
    if (client == null) {
      return [];
    }

    final driveApi = drive.DriveApi(client);
    try {
      String q = '';
      if (parentFolderId != null) {
        q += "'$parentFolderId' in parents";
      }
      if (query != null && query.isNotEmpty) {
        if (q.isNotEmpty) {
          q += " and ";
        }
        q += "name contains '$query'";
      }
      if (mimeType != null && mimeType.isNotEmpty) {
        if (q.isNotEmpty) {
          q += " and ";
        }
        q += "mimeType = '$mimeType'";
      }

      final result = await driveApi.files.list(
        q: q.isEmpty ? null : q,
        $fields: 'files(id, name, mimeType, modifiedTime, webViewLink)',
      );
      debugPrint('Google Drive API response: ${result.toJson()}');
      if (result.files == null || result.files!.isEmpty) {
        debugPrint('Google Drive API returned no files for query: $q');
      } else {
        for (var file in result.files!) {
          debugPrint(
              'File: id=${file.id}, name=${file.name}, mimeType=${file.mimeType}, webViewLink=${file.webViewLink}');
        }
      }
      return result.files ?? [];
    } catch (e) {
      debugPrint('Error calling Google Drive API files.list: $e');
      rethrow;
    }
  }

  Future<drive.File?> createFile(
      String name, String content, String mimeType) async {
    final client = await _getAuthClient();
    if (client == null) {
      return null;
    }

    final driveApi = drive.DriveApi(client);
    try {
      final fileToCreate = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.document';

      final media =
          drive.Media(Stream.fromIterable([content.codeUnits]), content.length);

      final file = await driveApi.files.create(
        fileToCreate,
        uploadMedia: media,
        $fields: 'id, name, webViewLink',
      );
      return file;
    } catch (e) {
      debugPrint('Error calling Google Drive API files.create: $e');
      rethrow;
    }
  }
}

