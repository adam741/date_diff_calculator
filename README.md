# Date Diff Calculator

A single-page Flutter app with a professional English UI to calculate the difference between two dates in years, months, and days (plus total days). No splash screen.

## Features
- Single page only, Material 3 design with gradients and elevated cards.
- Two date pickers (From / To).
- Accurate year/month/day difference calculation + total days.
- Poppins font via `google_fonts`.

## Run locally
```
flutter pub get
flutter run
```

## Release build (already configured, not debug)
The app is set up to build a **signed release** APK/AAB out of the box:
- `android/app/release-key.jks` — release keystore (RSA 2048, valid 10000 days), already generated.
- `android/key.properties` — signing credentials the build reads from:
  - `storePassword=DateDiff2026!`
  - `keyPassword=DateDiff2026!`
  - `keyAlias=release`
  - `storeFile=release-key.jks`
- `android/app/build.gradle` -> `buildTypes.release` now uses `signingConfigs.release` (not debug), with `minifyEnabled` and `shrinkResources` on.

Build with:
```
flutter build appbundle --release
```

**Important:** `key.properties` and `*.jks` are in `.gitignore` on purpose — they will NOT be pushed to GitHub. Keep a backup of `release-key.jks` and its passwords somewhere safe; if you lose it you can never update the app on Google Play under the same listing. Feel free to regenerate a new keystore with your own passwords (keytool) before your first Play Store upload if you'd rather use your own credentials.

## On Codemagic
This is a standard Flutter project (`pubspec.yaml` + `lib/` + `android/`) and can be linked to Codemagic directly. Just make sure `key.properties` and the `.jks` file are provided as secure environment files/variables in Codemagic (since they are gitignored and won't be in the repo).

Current `applicationId`: `com.dateflow.datediff` — change it in `android/app/build.gradle` (namespace + applicationId) and in `MainActivity.kt`'s package path if you need a different one.

## Structure
```
lib/main.dart              # full app UI and logic
pubspec.yaml                # dependencies
android/                    # Android project, release-ready
android/app/release-key.jks # release signing keystore
android/key.properties      # release signing credentials
```
