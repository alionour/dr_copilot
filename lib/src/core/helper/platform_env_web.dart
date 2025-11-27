String getPlatformEnv(String key) {
  // On web, environment variables are not available at runtime
  // They must be passed at compile time using --dart-define
  return '';
}
