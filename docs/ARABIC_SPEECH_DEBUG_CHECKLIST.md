# Arabic Speech Recognition - Debug Checklist

## Problem: Arabic speech returns empty transcript, English works fine

### When This Happens
- ✅ **English works**: App language = English, speak English → text appears
- ❌ **Arabic doesn't work**: App language = Arabic, speak Arabic → nothing appears

## Step-by-Step Debugging

### Step 1: Check Console Logs on App Start

Run the app in debug mode and look for these logs:

```bash
flutter run --debug
```

**Look for:**
```
[NativeSpeech] Initializing native speech recognition...
[NativeSpeech] Available locales: X
[NativeSpeech] All locales: en_US, ar_SA, fr_FR, ...
[NativeSpeech] Arabic locales found: Y
```

#### ✅ If you see: `Arabic locales found: 2` (or more)
Good! Your device supports Arabic. Continue to Step 2.

#### ❌ If you see: `Arabic locales found: 0`
**Problem**: Your device doesn't have Arabic language support installed.

**Fix for Android:**
1. Open Settings
2. Go to System → Languages & input → Languages
3. Add Arabic (العربية)
4. Try different variants: Saudi Arabia, Egypt, UAE
5. Restart the app

**Fix for iOS:**
1. Open Settings  
2. Go to General → Language & Region
3. Add Arabic under "Preferred Languages"
4. Go to General → Keyboard → Enable Dictation
5. Make sure Dictation has Arabic enabled
6. Restart the app

### Step 2: Test Speech Recognition with Arabic

1. Set app language to Arabic (Settings → Language → Arabic)
2. Go to Copilot Chat
3. Long-press the microphone button
4. Speak in Arabic (e.g., "مرحبا")
5. Release the button

**Check console for:**
```
[CopilotPage] Using app locale: ar
[CopilotPage] Voice input starting with app locale: ar
[HybridSpeech] Using native service for language: ar
[NativeSpeech] Starting to listen with language: ar_SA (requested: ar_SA)
```

### Step 3: Check What Happens During Recognition

**While speaking**, watch for:
```
[NativeSpeech] Status: listening
[NativeSpeech] Result: "مرحبا" (final: false)  ← Partial result
[NativeSpeech] Result: "مرحبا" (final: true)   ← Final result
```

#### ✅ If you see results with Arabic text
Your device is recognizing Arabic! Continue to Step 4.

#### ❌ If you see no results at all
**Possible causes:**

1. **Microphone permission not granted**
   - Check: Settings → Apps → dr_copilot → Permissions → Microphone → Allow
   - Test microphone: Try using voice input in another app

2. **Speaking too quietly**
   - Try speaking louder
   - Try speaking closer to the microphone
   - Test: Record a voice memo to check mic is working

3. **Wrong language detected**
   - Device might be listening for English even though locale is set to Arabic
   - This is a device/OS bug

### Step 4: Check Transcript Returned

**When you release the button**, watch for:
```
[NativeSpeech] Stopped listening, final transcript: "مرحبا" (length: 5)
[CopilotPage] Received transcript: "مرحبا" (length: 5, isEmpty: false)
[CopilotPage] Text field updated with transcript
```

#### ✅ If transcript is not empty and text field updates
Perfect! It's working!

#### ❌ If transcript is empty: `(length: 0)`
```
[NativeSpeech] WARNING: No speech was recognized...
[CopilotPage] Received transcript: "" (length: 0, isEmpty: true)
[CopilotPage] WARNING: Transcript is empty, not updating text field
```

**This means the device didn't recognize any speech.**

### Common Scenarios & Solutions

#### Scenario 1: Device Has No Arabic Locales
**Symptoms:**
```
[NativeSpeech] Arabic locales found: 0
[NativeSpeech] WARNING: No Arabic locales found!
```

**Solution:**
Add Arabic language to device as described in Step 1.

#### Scenario 2: Using Wrong Locale
**Symptoms:**
```
[NativeSpeech] WARNING: No locale found for ar, using first available: en_US
[NativeSpeech] Starting to listen with language: en_US (requested: ar_SA)
```

**This means:** Device has no Arabic, falling back to English.

**Solution:**
Add Arabic language to device.

#### Scenario 3: Recognition Returns Empty
**Symptoms:**
```
[NativeSpeech] Stopped listening, final transcript: "" (length: 0)
```

**Possible causes:**
1. Background noise interfering
2. Speaking during silence/pause periods
3. Microphone quality issues
4. Device doesn't understand Arabic accent/dialect

**Solutions:**
- Try in a quiet environment
- Speak clearly and at a normal pace
- Try different Arabic words (simpler ones first)
- Test phrases: "مرحبا", "واحد", "اثنان", "ثلاثة"

#### Scenario 4: Wrong Arabic Dialect
**Symptoms:**
```
[NativeSpeech] Starting to listen with language: ar_SA (requested: ar_SA)
```
But device expects Egyptian Arabic (`ar_EG`).

**Solution:**
The app automatically tries to match available locales. If you consistently have issues:
1. Check which Arabic locales are available: Look at initialization logs
2. Speak in Modern Standard Arabic (MSA) for best results
3. Try adding the specific Arabic dialect to your device

### Platform-Specific Issues

#### Android Issues

1. **Google App Required**
   - Android speech recognition requires Google app
   - Check if Google app is installed and up to date
   - Try: "Ok Google" to test if voice recognition works system-wide

2. **Offline Mode**
   - Arabic speech recognition works best with internet connection
   - Check internet connectivity
   - Some Android devices have better offline Arabic support than others

#### iOS Issues

1. **Dictation Must Be Enabled**
   - Settings → General → Keyboard → Enable Dictation
   - Make sure Arabic is included in Dictation languages

2. **Language Pack Download**
   - iOS downloads language packs on demand
   - First time using Arabic may require download
   - Check internet connection and storage space

3. **Siri & Dictation**
   - Test Siri with Arabic: "يا سيري"
   - If Siri doesn't work with Arabic, the app won't either

### Quick Tests

#### Test 1: System Voice Input Works?
1. Open any app with text input (Notes, Messages)
2. Tap microphone on keyboard
3. Speak in Arabic
4. Does it transcribe correctly?

**If NO:** It's a device/OS issue, not the app.
**If YES:** Continue investigating the app.

#### Test 2: Internet Connection
1. Disable internet
2. Try voice recognition
3. Enable internet
4. Try again

**Some devices require internet for Arabic recognition.**

#### Test 3: Different Arabic Phrases
Try these in order:
1. "مرحبا" (Hello)
2. "واحد اثنان ثلاثة" (One two three)
3. "كيف حالك" (How are you)
4. "أنا بخير" (I'm fine)

Numbers often work better than words initially.

### Advanced Debugging

#### Force Cloud-Based Recognition
The app now sets `onDevice: false` to prefer cloud-based recognition for better Arabic support.

If Arabic still doesn't work, check console for:
```
[NativeSpeech] Error: [error message]
```

Common errors:
- "Language not supported"
- "Network error"
- "Recognition service not available"

### What to Report

If Arabic still doesn't work after all checks, provide:

1. **Device Info:**
   - Device model: _______________
   - OS version: _______________
   - Android or iOS: _______________

2. **Console Logs** (copy these sections):
   ```
   [NativeSpeech] Available locales: ...
   [NativeSpeech] Arabic locales found: ...
   [NativeSpeech] Starting to listen with language: ...
   [NativeSpeech] Stopped listening, final transcript: ...
   ```

3. **System Voice Test Result:**
   - Does Arabic work in system keyboard? YES / NO

4. **Internet Status:**
   - Connected to WiFi / Mobile Data / Offline

5. **Tried Phrases:**
   - What did you say: _______________
   - What appeared (if anything): _______________

## Summary of Changes Made

Added comprehensive logging at every step:
1. Locale availability check with warnings
2. Language fallback with detailed logs
3. Recognition start/stop with transcript details
4. Empty transcript warnings
5. Text field update confirmations

**Next time you test**, the console will tell you exactly where the problem is!
