# Restore Files from RAR Backup
# This script extracts the RAR backup and compares files

$rarPath = "C:\Users\moham\Desktop\dary_lattest.rar"
$tempExtract = "$env:TEMP\dary_backup_restore"
$projectRoot = Get-Location

Write-Host "📦 Checking RAR backup..." -ForegroundColor Cyan

if (-not (Test-Path $rarPath)) {
    Write-Host "❌ RAR file not found at: $rarPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ RAR file found!" -ForegroundColor Green
Write-Host ""
Write-Host "To extract the RAR file, use one of these methods:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Method 1: Using WinRAR (if installed)" -ForegroundColor Cyan
Write-Host "  Right-click $rarPath → Extract to 'dary_backup'" -ForegroundColor White
Write-Host ""
Write-Host "Method 2: Using 7-Zip (if installed)" -ForegroundColor Cyan
Write-Host "  Right-click $rarPath → 7-Zip → Extract to 'dary_backup'" -ForegroundColor White
Write-Host ""
Write-Host "Method 3: Using PowerShell with Expand-Archive (if supported)" -ForegroundColor Cyan
Write-Host "  Expand-Archive -Path '$rarPath' -DestinationPath '$tempExtract' -Force" -ForegroundColor White
Write-Host ""
Write-Host "After extracting, compare files manually or use:" -ForegroundColor Yellow
Write-Host "  Compare-Item -Path '$projectRoot\lib\features\chat\chat_service.dart' -DifferenceObject '$tempExtract\lib\features\chat\chat_service.dart'" -ForegroundColor White

