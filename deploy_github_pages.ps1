# Simple GitHub Pages Deployment Script
# This script deploys the Flutter web build to GitHub Pages

Write-Host "🚀 Deploying to GitHub Pages..." -ForegroundColor Cyan

# Ensure we're in the project root
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $projectRoot) {
    $projectRoot = Get-Location
}
Set-Location $projectRoot

# Check if build/web exists
if (-not (Test-Path "build\web")) {
    Write-Host "❌ build/web not found! Building web..." -ForegroundColor Yellow
    flutter build web --release --base-href "/dary-app/"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Stash any changes
Write-Host "`n💾 Stashing changes..." -ForegroundColor Yellow
git stash push -m "Stash before gh-pages deploy" 2>$null

# Switch to gh-pages branch (or create orphan if it doesn't exist locally)
Write-Host "`n🌿 Checking out gh-pages branch..." -ForegroundColor Yellow
$hasGhPages = git show-ref --verify --quiet refs/heads/gh-pages 2>$null
$hasRemoteGhPages = git ls-remote --heads origin gh-pages 2>$null

if ($hasRemoteGhPages) {
    # Remote branch exists
    if ($hasGhPages) {
        git checkout gh-pages
        git reset --hard origin/gh-pages
    } else {
        git checkout -b gh-pages origin/gh-pages
    }
} else {
    # Create orphan branch if it doesn't exist
    git checkout --orphan gh-pages
}

# Remove all files except .git
Write-Host "`n🧹 Cleaning gh-pages branch..." -ForegroundColor Yellow
Get-ChildItem -Force | Where-Object { $_.Name -ne '.git' -and $_.Name -ne 'build' } | Remove-Item -Recurse -Force

# Copy build/web contents to root
Write-Host "`n📋 Copying web build files..." -ForegroundColor Yellow
if (Test-Path "build\web") {
    Copy-Item -Path "build\web\*" -Destination "." -Recurse -Force
    Write-Host "✅ Files copied successfully" -ForegroundColor Green
} else {
    Write-Host "❌ build/web directory not found!" -ForegroundColor Red
    git checkout main
    git stash pop 2>$null
    exit 1
}

# Add all files (using -f to force add files in .gitignore)
Write-Host "`n➕ Adding files..." -ForegroundColor Yellow
git add -f .

# Commit
Write-Host "`n💬 Committing..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "Deploy web build - $timestamp" 2>$null

# Push to gh-pages
Write-Host "`n🚀 Pushing to GitHub Pages..." -ForegroundColor Yellow
git push origin gh-pages --force

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Deployment successful!" -ForegroundColor Green
    Write-Host "🌐 Your app is available at:" -ForegroundColor Cyan
    Write-Host "   https://mohammedmilad1969.github.io/dary-app/" -ForegroundColor White
} else {
    Write-Host "`n❌ Push failed! Check your git remote configuration." -ForegroundColor Red
}

# Switch back to main
Write-Host "`n🔄 Switching back to main branch..." -ForegroundColor Yellow
git checkout main
git stash pop 2>$null

Write-Host "`n✨ Done!" -ForegroundColor Green

