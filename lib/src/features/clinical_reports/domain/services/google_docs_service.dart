import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'google_oauth_token_service.dart';

/// Service to interact with Google Docs API using bot account OAuth
///
/// This service uses a bot account's OAuth refresh token to:
/// - Create Google Docs
/// - Export Google Docs as HTML
/// - Delete Google Docs
///
/// All documents are created in the bot account's Drive (15GB free quota)
class GoogleDocsService {
  final GoogleOAuthTokenService _tokenService;

  GoogleDocsService(this._tokenService);

  /// Create a new Google Doc and return its ID
  Future<String> createDocument(String title) async {
    try {
      debugPrint('[GoogleDocsService] Creating document with title: $title');

      // Get valid access token
      final accessToken = await _tokenService.getAccessToken();

      // Create file metadata (Google Doc)
      final response = await http.post(
        Uri.parse('https://www.googleapis.com/drive/v3/files'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': title,
          'mimeType': 'application/vnd.google-apps.document',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          '[GoogleDocsService] ERROR creating document: ${response.body}',
        );
        throw Exception('Failed to create document: ${response.statusCode}');
      }

      final doc = jsonDecode(response.body);
      final docId = doc['id'] as String;

      debugPrint('[GoogleDocsService] Document created with ID: $docId');

      // Make document accessible via link (anyone with link can edit)
      debugPrint('[GoogleDocsService] Setting permissions...');
      await _setPermissions(docId, accessToken);

      debugPrint('[GoogleDocsService] Document creation complete!');
      return docId;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDocsService] ERROR creating document: $e');
      debugPrint('[GoogleDocsService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Set permissions on the document (anyone with link can edit)
  Future<void> _setPermissions(String docId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$docId/permissions',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': 'writer', 'type': 'anyone'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          '[GoogleDocsService] WARNING: Failed to set permissions: ${response.body}',
        );
        // Non-critical error, document still created
      } else {
        debugPrint('[GoogleDocsService] Permissions set successfully');
      }
    } catch (e) {
      debugPrint('[GoogleDocsService] WARNING: Error setting permissions: $e');
      // Non-critical error
    }
  }

  /// Get the URL for the embedded editor
  String getEditorUrl(String docId, {String? languageCode}) {
    var url = 'https://docs.google.com/document/d/$docId/edit';
    if (languageCode != null) {
      url += '?hl=$languageCode';
    }
    return url;
  }

  /// Get the URL for previewing the document (read-only)
  String getPreviewUrl(String docId, {String? languageCode}) {
    var url = 'https://docs.google.com/document/d/$docId/preview';
    if (languageCode != null) {
      url += '?hl=$languageCode';
    }
    return url;
  }

  /// Export the document as HTML string
  Future<String> exportAsHtml(String docId) async {
    try {
      debugPrint('[GoogleDocsService] Exporting document $docId as HTML...');

      final accessToken = await _tokenService.getAccessToken();

      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$docId/export?mimeType=text/html',
        ),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[GoogleDocsService] ERROR exporting document: ${response.body}',
        );
        throw Exception('Failed to export document: ${response.statusCode}');
      }

      debugPrint('[GoogleDocsService] Document exported successfully');
      return response.body;
    } catch (e, stackTrace) {
      debugPrint('[GoogleDocsService] ERROR exporting document: $e');
      debugPrint('[GoogleDocsService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Delete the document from Drive
  Future<void> deleteDocument(String docId) async {
    try {
      debugPrint('[GoogleDocsService] Deleting document $docId...');

      final accessToken = await _tokenService.getAccessToken();

      final response = await http.delete(
        Uri.parse('https://www.googleapis.com/drive/v3/files/$docId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        debugPrint(
          '[GoogleDocsService] ERROR deleting document: ${response.body}',
        );
        throw Exception('Failed to delete document: ${response.statusCode}');
      }

      debugPrint('[GoogleDocsService] Document deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('[GoogleDocsService] ERROR deleting document: $e');
      debugPrint('[GoogleDocsService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

