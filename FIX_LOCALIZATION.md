# Fix for Localization File Errors

## The Problem
After running `flutter clean`, the generated localization files are deleted and need to be regenerated.

## The Solution

**ALWAYS run these commands in this order:**

```powershell
flutter gen-l10n
flutter run -d chrome
```

## Quick Fix Script

I've created a script that does this automatically:

```powershell
.\run_app.ps1
```

This script will:
1. Generate the localization files
2. Verify they exist
3. Run your app

## If You Still Get Errors

1. **Close your IDE completely** (VS Code, Android Studio, etc.)
2. Run: `flutter gen-l10n`
3. **Reopen your IDE**
4. Run: `flutter run -d chrome`

## Why This Happens

The `flutter clean` command removes all generated files, including the localization files. The `flutter pub get` command with `generate: true` should regenerate them, but for l10n files, you need to explicitly run `flutter gen-l10n`.

## Files That Must Exist

These files must exist before compilation:
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_ar.dart`

You can verify they exist by running:
```powershell
Get-ChildItem lib\l10n\*.dart
```

