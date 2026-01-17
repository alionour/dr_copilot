// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// One-time OAuth setup tool to get refresh token for bot account
///
/// Usage:
/// 1. Run: dart run tools/oauth_setup.dart
/// 2. Copy the URL printed to the terminal
/// 3. Paste into browser and sign in
/// 4. Tool will capture the code and print the refresh token
void main() async {
  print('='.repeat(60));
  print('Google OAuth Setup Tool for Dr Copilot (Manual Mode)');
  print('='.repeat(60));
  print('');

  // Helper to sanitize inputs
  String sanitize(String? value) {
    if (value == null) return '';
    return value.trim().replaceAll('"', '').replaceAll("'", '');
  }

  // Load OAuth credentials
  print('Loading OAuth credentials...');
  final clientId = sanitize(
    Platform.environment['GOOGLE_OAUTH_CLIENT_ID'] ?? 'YOUR_CLIENT_ID_HERE',
  );
  final clientSecret = sanitize(
    Platform.environment['GOOGLE_OAUTH_CLIENT_SECRET'] ??
        'YOUR_CLIENT_SECRET_HERE',
  );

  if (clientId.contains('YOUR_CLIENT_ID') || clientId.isEmpty) {
    print('❌ ERROR: GOOGLE_OAUTH_CLIENT_ID not set or invalid.');
    exit(1);
  }

  print('✓ OAuth credentials loaded');
  print('  Client ID: $clientId');
  print('');

  // Start local server to receive OAuth callback
  print('Starting local server on port 8080...');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('✓ Server started at http://localhost:8080');
  print('');

  // Build authorization URL
  final scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/documents',
  ];

  final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'client_id': clientId,
    'redirect_uri': 'http://localhost:8080/auth/callback',
    'response_type': 'code',
    'scope': scopes.join(' '),
    'access_type': 'offline',
    'prompt': 'consent',
  });

  print('='.repeat(60));
  print('ACTION REQUIRED:');
  print('='.repeat(60));
  print('');
  print('1. COPY this URL exactly:');
  print('');
  print(authUrl.toString());
  print('');
  print('2. PASTE it into your browser');
  print('3. Sign in with your BOT ACCOUNT');
  print('');
  print('Waiting for authorization...');

  String? authCode;

  await for (HttpRequest request in server) {
    if (request.uri.path == '/auth/callback') {
      authCode = request.uri.queryParameters['code'];

      if (authCode != null) {
        // Send success response to browser
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('''
            <!DOCTYPE html>
            <html>
            <head><title>Authorization Successful</title></head>
            <body style="font-family: Arial; text-align: center; padding: 50px;">
              <h1>✓ Authorization Successful!</h1>
              <p>You can close this window and return to the terminal.</p>
            </body>
            </html>
          ''');
        await request.response.close();
        break;
      } else {
        // Error response
        final error = request.uri.queryParameters['error'];
        request.response
          ..statusCode = 400
          ..write('Authorization failed: $error');
        await request.response.close();
        print('❌ Authorization failed: $error');
        await server.close();
        exit(1);
      }
    } else {
      request.response
        ..statusCode = 404
        ..write('Not found');
      await request.response.close();
    }
  }

  await server.close();

  if (authCode == null) {
    print('❌ No authorization code received');
    exit(1);
  }

  print('✓ Authorization code received');
  print('');

  // Exchange authorization code for tokens
  print('Exchanging authorization code for tokens...');

  final tokenResponse = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    body: {
      'code': authCode,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': 'http://localhost:8080/auth/callback',
      'grant_type': 'authorization_code',
    },
  );

  if (tokenResponse.statusCode != 200) {
    print('❌ Token exchange failed:');
    print(tokenResponse.body);
    exit(1);
  }

  final tokens = jsonDecode(tokenResponse.body);
  final refreshToken = tokens['refresh_token'];
  final accessToken = tokens['access_token'];

  if (refreshToken == null) {
    print('❌ No refresh token received!');
    print('   Make sure you set access_type=offline and prompt=consent');
    print('   Response: ${tokenResponse.body}');
    exit(1);
  }

  print('✓ Tokens received successfully!');
  print('');
  print('='.repeat(60));
  print('SUCCESS! Save this refresh token:');
  print('='.repeat(60));
  print('');
  print(refreshToken);
  print('');
  print('='.repeat(60));
  print('');
  print('Next Steps:');
  print('1. Copy the refresh token above');
  print('2. Store it securely:');
  print('   - In Doppler: GOOGLE_REFRESH_TOKEN');
  print('3. NEVER commit this token to git!');
  print('');
  print('Access token (expires in 1 hour):');
  print(accessToken);
  print('');
  print('Setup complete! ✓');
}

extension on String {
  String repeat(int times) => List.filled(times, this).join();
}
