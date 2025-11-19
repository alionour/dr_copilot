# Arabic Speech Recognition Troubleshooting Guide

## Overview
The app uses a **Hybrid Speech Recognition Service** that automatically routes between:
- **Native Speech Recognition** (speech_to_text) for Arabic and other languages
- **Deepgram** for English (higher quality when available)

## How to Test Arabic Speech Recognition

### 1. Check Device Language Support
When you start the app, check the debug console for:
```
[NativeSpeech] Initializing native speech recognition...
[NativeSpeech] Available locales: <number>
[NativeSpeech] All locales: <list of locale IDs>
[NativeSpeech] Arabic locales found: <number>
[NativeSpeech] Arabic locales: ar_SA, ar_EG, ar_AE, etc.
```

### 2. Using Voice Input
1. **Long press** the microphone button
2. Speak in Arabic
3. Release when done
4. Check console for:
```
[HybridSpeech] Using native service for language: ar
[NativeSpeech] Starting to listen with language: ar_SA (requested: ar_SA)
[NativeSpeech] Result: "<your speech>" (final: true/false)
[NativeSpeech] Stopped listening, final transcript: "<your speech>" (length: X)
```

## Common Issues & Solutions

### Issue 1: No Arabic Locales Available
**Symptoms:**
```
[NativeSpeech] Arabic locales found: 0
```

**Solutions:**
1. **Android:**
   - Go to Settings → System → Languages & input → Languages
   - Add Arabic (العربية) if not present
   - Try different Arabic variants (Saudi Arabia, Egypt, UAE)

2. **iOS:**
   - Go to Settings → General → Language & Region
   - Add Arabic under Preferred Languages
   - Enable Dictation for Arabic: Settings → General → Keyboard → Enable Dictation

3. **Windows/Desktop:**
   - Speech recognition may have limited language support
   - Check Windows Speech settings for Arabic language pack

### Issue 2: Empty Transcript Returned
**Symptoms:**
```
[NativeSpeech] WARNING: No speech was recognized...
[NativeSpeech] Stopped listening, final transcript: "" (length: 0)
```

**Solutions:**
1. **Check Microphone Permissions:**
   - Android: Settings → Apps → dr_copilot → Permissions → Microphone → Allow
   - iOS: Settings → dr_copilot → Microphone → Enable

2. **Test Microphone:**
   - Try using another app with voice input (Google Keyboard, voice memos)
   - Ensure microphone is not muted or blocked

3. **Speech Recognition Not Working:**
   - Restart the app
   - Try speaking louder or closer to microphone
   - Check if speech recognition works in system keyboard

### Issue 3: Wrong Language Detected
**Symptoms:**
- App is in Arabic but speech recognition uses English

**Check:**
```
[CopilotPage] Using app locale: ar
[HybridSpeech] Language changed to: ar
[NativeSpeech] Language preference set to: ar_SA (from code: ar)
```

**Important:** The app uses **APP locale** (not device locale)!

**Solutions:**
1. **Change app language**: Use the language selector in the app settings
2. The app supports: English (en) and Arabic (ar)
3. Speech recognition will automatically match the app's current language
4. Device language setting is NOT used - only app language matters

### Issue 4: Locale Fallback
**Symptoms:**
```
[NativeSpeech] Requested locale ar_SA not found, using ar_EG
```

**This is normal!** The app will automatically find the best available Arabic locale on your device.

## Technical Details

### Language Routing Logic
```dart
// In HybridSpeechRecognitionService
if (languageCode == 'ar' || 'fr' || 'es' || 'de') {
  // Use Native Speech Recognition
} else {
  // Use Deepgram (English)
}
```

### Supported Arabic Locales
The app will try these in order:
1. `ar_SA` - Arabic (Saudi Arabia) - Default
2. `ar_EG` - Arabic (Egypt)
3. `ar_AE` - Arabic (UAE)
4. `ar_JO` - Arabic (Jordan)
5. Any other `ar_*` locale available on device

### Speech Recognition Flow
1. User long-presses microphone button
2. App checks current **APP locale** (`context.locale.languageCode`) - NOT device locale
3. Logs: `[CopilotPage] Voice input starting with app locale: <code>`
4. HybridService routes to Native service for Arabic
5. Native service checks available locales on device
6. Finds best matching Arabic locale
7. Starts listening with that locale
8. Streams partial results as user speaks
9. Returns final transcript when user releases button

**Key Point:** The app uses its own language setting (EasyLocalization), independent of device language!

## Debug Mode

To enable verbose logging, run the app in debug mode:
```bash
flutter run --debug
```

Watch the console for all `[NativeSpeech]` and `[HybridSpeech]` messages.

## Alternative: Force Native Service for All Languages

If you want to test native speech recognition for all languages (not just Arabic), modify:

**File:** `lib/src/features/copilot_chat/data/services/hybrid_speech_recognition_service.dart`

Change:
```dart
AbstractSpeechRecognitionService _getServiceForLanguage() {
  // Force native service for testing
  return _nativeService;
}
```

## Reporting Issues

When reporting Arabic speech recognition issues, include:
1. Device type (Android/iOS/Desktop)
2. OS version
3. Console logs showing:
   - Available locales
   - Language being used
   - Transcript results
4. Steps to reproduce
5. What you spoke vs what was recognized

## Additional Resources

- [speech_to_text package](https://pub.dev/packages/speech_to_text)
- [Supported Languages](https://cloud.google.com/speech-to-text/docs/languages)
- Android Speech Recognition: Requires Google app installed
- iOS Speech Recognition: Built into iOS, requires language pack downloaded
