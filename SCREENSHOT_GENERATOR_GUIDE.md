
# Store Screenshot Generator

This guide explains how to use the automated screenshot generator for the Dr. Copilot store listings.

## Prerequisites

-   Use a physical device or emulator/simulator with a typical phone screen size (e.g., Pixel or iPhone).
-   Ensure you have configured `adb` (Android) or `simctl` (iOS) if you want to pull screenshots easily, although usually `flutter drive` handles it.
-   **Important**: You must be able to sign in to the app on the device manually during the test execution.

## How to Run

### Command Line

Run the integration test using `flutter test integration_test`. Since we want to capture screenshots, we usually use the `integration_test` driver.

#### Android / iOS / Windows

```bash
flutter test integration_test/screenshot_generator_test.dart
```

**Note for Android:** By default, screenshots taken with `binding.takeScreenshot` are saved on the device.
To pull them efficiently, you might need a driver script, OR you can just run the test and then look in the device storage.

On Android, screenshots are typically saved in `/sdcard/Android/data/com.alionour.drcopilot/files/` (or similar package name path).

### The "Manual Login" Step

The test determines if you are logged out. If you see the "Login Page":
1.  The test console will print: `Please sign in manually...`
2.  Interact with the running app on the device.
3.  Tap "Sign and with Google" and complete the flow.
4.  Once you land on the Home Page, the test will detect it and continue automatically.

### Where are the screenshots?

On **Android** (files are on device):
You can pull them using `adb`:
```bash
adb pull /sdcard/Android/data/<package_name>/files/01_login_screen.png .
```
(Replace `<package_name>` with your app package, likely `com.alionour.drcopilot` or similar check `android/app/build.gradle`).

On **Windows**:
Screenshots should be saved in the execution directory or a temp folder.

## Troubleshooting

-   **Test Timed Out**: If you take longer than 5 minutes to log in, the test fails.
-   **Screenshots are black/empty**: Ensure the app has permission to write to storage if needed (though usually app-private storage is fine).
