String getPlatformEnv(String key) {
  // On web, environment variables are not available at runtime
  // They must be passed at compile time using --dart-define
  // Map known keys to environment values
  const env = {
    'GOOGLE_OAUTH_CLIENT_ID': String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
    'GOOGLE_OAUTH_CLIENT_SECRET': String.fromEnvironment(
      'GOOGLE_OAUTH_CLIENT_SECRET',
    ),
    'GOOGLE_REFRESH_TOKEN': String.fromEnvironment('GOOGLE_REFRESH_TOKEN'),
    // Add other keys here as needed
  };
  return env[key] ?? '';
}
