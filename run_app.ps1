# Always generate l10n files before running Flutter app
Write-Host "=== Generating Localization Files ===" -ForegroundColor Cyan
flutter gen-l10n

# Verify files exist
$requiredFiles = @(
    "lib\l10n\app_localizations.dart",
    "lib\l10n\app_localizations_en.dart", 
    "lib\l10n\app_localizations_ar.dart"
)

$allExist = $true
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "ERROR: $file does not exist!" -ForegroundColor Red
        $allExist = $false
    }
}

if (-not $allExist) {
    Write-Host "`nFailed to generate required localization files!" -ForegroundColor Red
    Write-Host "Please run 'flutter gen-l10n' manually and check for errors." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✓ All localization files generated successfully!" -ForegroundColor Green
Write-Host "`n=== Starting Flutter App ===" -ForegroundColor Cyan
flutter run -d chrome

