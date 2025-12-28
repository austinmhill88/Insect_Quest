# Setup Guide for Developers

This guide provides step-by-step instructions for setting up the InsectQuest development environment.

## Quick Start

If you're already familiar with Flutter development:

```bash
git clone https://github.com/austinmhill88/Insect_Quest.git
cd Insect_Quest/Insect_quest
flutter pub get
# Edit android/app/src/main/res/values/strings.xml with your Google Maps API key
flutter run
```

## Detailed Setup

### Step 1: Install Prerequisites

#### 1.1 Install Flutter

**macOS:**
```bash
# Download Flutter
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Add to your shell profile (e.g., ~/.zshrc or ~/.bash_profile)
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zshrc
```

**Linux:**
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install curl git unzip xz-utils zip libglu1-mesa

# Download Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:$HOME/flutter/bin"

# Add to ~/.bashrc
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
```

**Windows:**
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to PATH

#### 1.2 Verify Flutter Installation

```bash
flutter doctor
```

Address any issues reported by `flutter doctor`.

#### 1.3 Install Android Studio

1. Download from https://developer.android.com/studio
2. Run the installer
3. In the setup wizard:
   - Select "Standard" installation
   - Choose your preferred theme
   - Let it download Android SDK, SDK Platform-Tools, and Android SDK Build-Tools

#### 1.4 Configure Android SDK

In Android Studio:
1. Open Settings/Preferences → Appearance & Behavior → System Settings → Android SDK
2. Select "SDK Platforms" tab
3. Check "Android API 33" (or latest)
4. Select "SDK Tools" tab
5. Check:
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android SDK Tools
   - Android Emulator
6. Click "Apply" to install

#### 1.5 Install Flutter and Dart Plugins

In Android Studio:
1. File → Settings (or Preferences on macOS)
2. Plugins → Marketplace
3. Search for "Flutter" and install
4. This will also install the Dart plugin
5. Restart Android Studio

### Step 2: Set Up Android Emulator

#### 2.1 Create Virtual Device

1. In Android Studio: Tools → AVD Manager
2. Click "Create Virtual Device"
3. Select a device (e.g., Pixel 4)
4. Download and select a system image (e.g., API 33)
5. Name it and click "Finish"

#### 2.2 Start Emulator

```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>
```

Or from Android Studio: AVD Manager → Click ▶️ button

### Step 3: Get Google Maps API Key

#### 3.1 Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Note the project name

#### 3.2 Enable Maps SDK for Android

1. In the Google Cloud Console
2. APIs & Services → Library
3. Search for "Maps SDK for Android"
4. Click it and press "Enable"

#### 3.3 Create API Key

1. APIs & Services → Credentials
2. Click "Create Credentials" → API Key
3. Copy the API key

#### 3.4 (Optional) Restrict API Key

1. Click on the API key you just created
2. Under "Application restrictions":
   - Select "Android apps"
   - Add your package name: `com.example.insect_quest`
   - Add your SHA-1 certificate fingerprint (for release builds)
3. Under "API restrictions":
   - Select "Restrict key"
   - Check "Maps SDK for Android"
4. Save

### Step 4: Clone and Configure Project

#### 4.1 Clone Repository

```bash
git clone https://github.com/austinmhill88/Insect_Quest.git
cd Insect_Quest/Insect_quest
```

#### 4.2 Install Dependencies

```bash
flutter pub get
```

#### 4.3 Configure Google Maps API Key

Edit `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="google_maps_api_key">AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX</string>
</resources>
```

Replace with your actual API key from Step 3.3.

### Step 5: Build and Run

#### 5.1 Check Connected Devices

```bash
flutter devices
```

You should see your emulator or connected physical device.

#### 5.2 Run the App

```bash
flutter run
```

Or in Android Studio:
1. Open the project
2. Wait for Gradle sync to complete
3. Select your device from the dropdown
4. Click the Run button (green ▶️)

#### 5.3 Hot Reload (During Development)

While the app is running:
- Press `r` in the terminal for hot reload
- Press `R` for hot restart
- Or save files in your IDE (if hot reload on save is enabled)

### Step 6: Development Workflow

#### 6.1 Code Analysis

```bash
# Check for issues
flutter analyze

# Format code
flutter format lib/
```

#### 6.2 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart
```

#### 6.3 Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## Troubleshooting

### Flutter Doctor Issues

**Problem:** `flutter doctor` shows issues

**Solutions:**
- Accept Android licenses: `flutter doctor --android-licenses`
- Install missing components via Android Studio SDK Manager
- Ensure Android SDK path is set: `flutter config --android-sdk /path/to/sdk`

### Gradle Build Failures

**Problem:** Build fails with Gradle errors

**Solutions:**
```bash
# Clean build
flutter clean
flutter pub get

# Update Gradle wrapper (if needed)
cd android
./gradlew wrapper --gradle-version=7.5
cd ..
```

### Camera Not Working

**Problem:** Camera preview is black or errors

**Solutions:**
- Physical device works better than emulator for camera
- Ensure camera permission is granted
- Check AndroidManifest.xml has `<uses-permission android:name="android.permission.CAMERA" />`
- Enable camera in emulator settings (limited functionality)

### Map Not Showing

**Problem:** Google Map is blank or shows error

**Solutions:**
- Verify API key is correct in `strings.xml`
- Check "Maps SDK for Android" is enabled in Google Cloud Console
- Wait a few minutes after enabling API (propagation delay)
- Check API key restrictions aren't blocking the app
- Review logcat for specific error messages

### Location Services

**Problem:** Cannot get location

**Solutions:**
- Grant location permission in device settings
- Enable location services on device/emulator
- In emulator: Use Extended Controls (⋯) → Location to set fake location

### Dependency Conflicts

**Problem:** Pub get fails or dependency errors

**Solutions:**
```bash
# Clear pub cache
flutter pub cache repair

# Update dependencies
flutter pub upgrade

# If issues persist, try:
rm -rf .dart_tool
rm pubspec.lock
flutter pub get
```

## IDE Configuration

### VS Code

Install extensions:
- Flutter
- Dart

Configuration (`.vscode/settings.json`):
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalPackageLibraries": true,
  "editor.formatOnSave": true
}
```

### Android Studio

Preferences:
- Languages & Frameworks → Flutter → Set Flutter SDK path
- Editor → Code Style → Dart → Set from: Dart Style Guide
- Editor → General → Code Completion → Show suggestions as you type

## Useful Commands

```bash
# Check Flutter version
flutter --version

# Upgrade Flutter
flutter upgrade

# List available devices
flutter devices

# Run with specific device
flutter run -d <device_id>

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Analyze code
flutter analyze

# Format code
flutter format .

# Build APK (release)
flutter build apk --release

# Build for specific architecture
flutter build apk --target-platform android-arm64

# Install to device
flutter install

# Capture logs
flutter logs
```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Google Maps Flutter Plugin](https://pub.dev/packages/google_maps_flutter)
- [Camera Plugin](https://pub.dev/packages/camera)
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## Getting Help

If you encounter issues not covered here:

1. Check [Flutter Issue Tracker](https://github.com/flutter/flutter/issues)
2. Review [Stack Overflow Flutter Tag](https://stackoverflow.com/questions/tagged/flutter)
3. Consult the [Flutter Discord](https://discord.gg/flutter)
4. Read the docs: `flutter help`

---

Happy Coding! 🚀
