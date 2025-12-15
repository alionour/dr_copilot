import 'dart:io' as io;

String getPlatformEnv(String key) {
  return io.Platform.environment[key] ?? '';
}

