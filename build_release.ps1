# Build Release Script for Play Store Deployment
# This script builds the Android App Bundle (AAB) for Google Play Store

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Release AAB for Play Store" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterCheck = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Flutter found" -ForegroundColor Green
Write-Host ""

# Check if we're in the frontend directory
$currentDir = Get-Location
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml not found. Please run this script from the frontend directory." -ForegroundColor Red
    exit 1
}

# Check if key.properties exists
Write-Host "Checking signing configuration..." -ForegroundColor Yellow
if (-not (Test-Path "android\key.properties")) {
    Write-Host "WARNING: android\key.properties not found!" -ForegroundColor Yellow
    Write-Host "Signing configuration may be incomplete." -ForegroundColor Yellow
} else {
    Write-Host "✓ Signing configuration found" -ForegroundColor Green
}

# Check if keystore file exists
if (-not (Test-Path "my-release-key.jks")) {
    Write-Host "WARNING: my-release-key.jks not found in frontend directory!" -ForegroundColor Yellow
    Write-Host "The build may fail if keystore is not properly configured." -ForegroundColor Yellow
} else {
    Write-Host "✓ Keystore file found" -ForegroundColor Green
}
Write-Host ""

# Display current version
Write-Host "Current app version:" -ForegroundColor Yellow
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*([^\s]+)') {
    $version = $matches[1]
    Write-Host "  Version: $version" -ForegroundColor Cyan
} else {
    Write-Host "  Could not determine version" -ForegroundColor Yellow
}
Write-Host ""

# Clean previous builds
Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter clean failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Clean completed" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build AAB
Write-Host "Building Android App Bundle (AAB)..." -ForegroundColor Yellow
Write-Host "This may take several minutes..." -ForegroundColor Yellow
Write-Host ""

flutter build appbundle --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Build failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Build Successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Locate the AAB file
$aabPath = "build\app\outputs\bundle\release\app-release.aab"

if (Test-Path $aabPath) {
    $aabFile = Get-Item $aabPath
    $fileSize = [math]::Round($aabFile.Length / 1MB, 2)
    
    Write-Host "AAB File Location:" -ForegroundColor Cyan
    Write-Host "  $((Get-Location).Path)\$aabPath" -ForegroundColor White
    Write-Host ""
    Write-Host "File Size: $fileSize MB" -ForegroundColor Cyan
    Write-Host ""
    
    # Check file size warning
    if ($fileSize -gt 150) {
        Write-Host "WARNING: AAB file is larger than 150MB!" -ForegroundColor Yellow
        Write-Host "Google Play has a 150MB limit for AAB files." -ForegroundColor Yellow
        Write-Host "Consider using App Bundle expansion files if needed." -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Go to Google Play Console: https://play.google.com/console" -ForegroundColor White
    Write-Host "2. Create a new app or select existing app" -ForegroundColor White
    Write-Host "3. Navigate to Production > Releases" -ForegroundColor White
    Write-Host "4. Upload the AAB file: $aabPath" -ForegroundColor White
    Write-Host "5. Complete store listing and submit for review" -ForegroundColor White
    Write-Host ""
    Write-Host "See PLAY_STORE_DEPLOYMENT.md for detailed instructions." -ForegroundColor Cyan
} else {
    Write-Host "WARNING: AAB file not found at expected location!" -ForegroundColor Yellow
    Write-Host "Expected: $aabPath" -ForegroundColor Yellow
    Write-Host "Please check the build output above for errors." -ForegroundColor Yellow
}

Write-Host ""
