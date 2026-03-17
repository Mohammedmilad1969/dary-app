# Wrapper script that always generates l10n files before running
Write-Host "Ensuring localization files are generated..." -ForegroundColor Yellow
flutter gen-l10n

if (-not (Test-Path "lib\l10n\app_localizations.dart")) {
    Write-Host "ERROR: Failed to generate localization files!" -ForegroundColor Red
    exit 1
}

Write-Host "Starting Flutter app..." -ForegroundColor Green
flutter run -d chrome

