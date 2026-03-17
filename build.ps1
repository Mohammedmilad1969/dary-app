# Build script that ensures l10n files are generated
param(
    [switch]$Clean
)

if ($Clean) {
    Write-Host "Cleaning Flutter build..." -ForegroundColor Yellow
    flutter clean
}

Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Generating localization files..." -ForegroundColor Yellow
flutter gen-l10n

# Verify files exist
if (-not (Test-Path "lib\l10n\app_localizations.dart")) {
    Write-Host "ERROR: Localization files were not generated!" -ForegroundColor Red
    exit 1
}

Write-Host "Localization files generated successfully!" -ForegroundColor Green
Write-Host "Starting Flutter app..." -ForegroundColor Green
flutter run -d chrome

