# AEC (Acoustic Echo Cancellation) — Implementation Reference

## Goal
Prevent the AI's speech (played through speaker) from being heard by the microphone and re-sent to the server, which would cause the AI to hear its own voice.

## Architecture (3 layers)

### 1. Platform-level AEC (`RecordConfig`)
**File:** `gemini_live_service.dart:406-418`, `speech_recognition_service.dart:357-365`

```dart
RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 16000,
  numChannels: 1,
  echoCancel: true,          // Enables hardware AEC
  noiseSuppress: true,        // Enables noise suppression
  audioInterruption: AudioInterruptionMode.none,  // Prevents auto-pause on focus loss
  androidConfig: AndroidRecordConfig(
    audioSource: AndroidAudioSource.voiceCommunication,  // VOICE_COMMUNICATION
    speakerphone: true,                                   // Speaker output
    audioManagerMode: AudioManagerMode.modeInCommunication, // MODE_IN_COMM
  ),
)
```

**Commit:** `97d4f21` — "fix: enable AEC + Timestamp serialization + debug logging"

**How it works:**
- `echoCancel: true` maps to `MediaRecorder.AudioSource.VOICE_COMMUNICATION` on Android, enabling hardware echo cancellation in the audio HAL.
- `voiceCommunication` + `modeInCommunication` tells the audio driver this is a two-way voice call, giving AEC the full audio path so it can subtract the speaker waveform from the mic input.
- `speakerphone: true` routes AI playback to the loudspeaker while the mic stays active.
- Native `AudioRecordImpl` logs `[mute]` when AEC is actively suppressing speaker echo, and `[fine]` when user voice is detected.

### 2. Audio Interruption Handling
**Commit:** `97d4f21`

```dart
audioInterruption: AudioInterruptionMode.none,
```

Without this, Android auto-pauses the recorder when audio focus is lost (during AI playback), breaking the AEC feedback loop and preventing barge-in.

### 3. Audio Gating (`_shouldSendAudio`)
**Files:** `gemini_live_service.dart` (multiple locations)

When `_shouldSendAudio` is `false`, mic audio is still recorded locally (for RMS calculation and UI visualizer) but NOT sent to the server. This prevents the server from hearing its own audio during certain states.

**Evolution (chronological commits):**
1. `6098c5b` — Added `turnComplete: true` after tool response (server wasn't responding)
2. `a8e9c52` — Paused mic audio during AI playback (to unblock server)
3. `f326bd1` — Removed `turnComplete` signal (caused WebSocket 1007), kept gating
4. `3cbb528` — Gated mic at tool call boundary instead of playback (initial response is sometimes text-only, so playback gate never fires)
5. `5feb52e` — Added `_resumeAudioOnNextContent` flag to resume audio only when server sends next content
6. *(current)* — `sendToolResponse` alone (no `turnComplete`); server must continue automatically per API spec. The standalone `turnComplete: true` was tried twice — first caused WebSocket 1007 (audio was streaming), second caused `_Map<dynamic, dynamic>` type cast crash in `firebase_ai` SDK's `parseServerMessage`.

### 4. Barge-in

#### Before (automatic, removed)
**Commit:** `3cbb528`

```dart
// Local RMS-based barge-in
if (_currentState == LiveChatState.speaking && level > 0.03) {
  await _clearAudioQueue();
  _shouldSendAudio = true;
  _setState(LiveChatState.listening);
}
```

#### After (manual, current)
**Commit:** *(not yet committed — current working state)*

Removed automatic RMS barge-in. User must tap the screen:

```dart
// In GeminiLiveService
Future<void> bargeIn() async {
  if (_currentState == LiveChatState.speaking) {
    await _clearAudioQueue();
    _shouldSendAudio = true;
    _setState(LiveChatState.listening);
  }
}
```

UI shows "Tap to interrupt" label during `speaking` state. Orb is wrapped in `GestureDetector` calling `bargeIn()`.

## AEC Flow at Runtime

1. Mic streams 16kHz PCM to Gemini server (while `_shouldSendAudio == true`)
2. Server responds with AI audio played via `audioplayers` on speaker
3. AEC in hardware subtracts the speaker waveform from the mic signal
4. Native logs show: `[mute]` = AEC suppressing echo, `[fine]` = user voice detected
5. If user taps screen during playback (or server sends `interrupted: true`), audio queue cleared and state → `listening`

## Key Files

| File | Role |
|---|---|
| `lib/src/features/copilot_chat/data/services/gemini_live_service.dart` | Main AEC + audio gating + barge-in logic |
| `lib/src/features/copilot_chat/data/services/speech_recognition_service.dart` | Deepgram-based STT (also has `echoCancel: true`) |
| `lib/src/features/copilot_chat/presentation/pages/live_chat_page.dart` | UI with orb + tap-to-interrupt |
| `assets/translations/*.json` | `tapToInterrupt` key (5 locales) |

## Patched SDK (firebase_ai)

**Issue**: `parseServerMessage` in `live_api.dart:394` uses `jsonObject as Map<String, dynamic>`. The Dart runtime sometimes produces `_Map<dynamic, dynamic>` from `json.decode`, and the strict generic `as` cast fails with:
```
type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?'
```

**Fix**: Override `firebase_ai` via `dependency_overrides` in `pubspec.yaml` pointing to `packages/firebase_ai`. Patch changes:
- Line 394: `Map json = jsonObject as Map;` (raw `Map` cast, avoids generic type check)
- Lines 397, 410, 427: Use `(value as Map).cast<String, dynamic>()` to safely convert

This prevents session crashes when the server sends messages that parse as `_Map<dynamic, dynamic>`.

## Platform Quirks

- **Windows**: Firestore `persistenceEnabled: false` required (`main.dart:69`) to avoid platform channel threading crash.
- **Android AEC**: Only works reliably with `voiceCommunication` + `modeInCommunication` + `speakerphone: true`. Without all three, echo leaks through.
- **Record package `[mute]`/`[fine]` logging**: Comes from `AudioRecordImpl` — `[mute]` means AEC is active and suppressing audio, `[fine]` means user voice is passing through.
