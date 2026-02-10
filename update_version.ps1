# Version Update Script for Play Store
# This script helps you update the version number and build a new AAB

param(
    [string]$NewVersion = "",
    [int]$NewVersionCode = 0
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Version Update for Play Store" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the frontend directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERROR: pubspec.yaml not found. Please run this script from the frontend directory." -ForegroundColor Red
    exit 1
}

# Read current version
$pubspecContent = Get-Content "pubspec.yaml" -Raw
$currentVersion = ""
if ($pubspecContent -match 'version:\s*([^\s]+)') {
    $currentVersion = $matches[1]
    Write-Host "Current version: $currentVersion" -ForegroundColor Yellow
} else {
    Write-Host "ERROR: Could not read current version from pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Parse current version
$versionParts = $currentVersion -split '\+'
$currentVersionName = $versionParts[0]
$currentVersionCode = [int]$versionParts[1]

Write-Host "  Version Name: $currentVersionName" -ForegroundColor Cyan
Write-Host "  Version Code: $currentVersionCode" -ForegroundColor Cyan
Write-Host ""

# Get new version if not provided
if ([string]::IsNullOrEmpty($NewVersion)) {
    Write-Host "Enter new version (e.g., 1.0.2 or press Enter to auto-increment):" -ForegroundColor Yellow
    $userInput = Read-Host
    if ([string]::IsNullOrEmpty($userInput)) {
        # Auto-increment patch version
        $versionNumbers = $currentVersionName -split '\.'
        $major = [int]$versionNumbers[0]
        $minor = [int]$versionNumbers[1]
        $patch = [int]$versionNumbers[2]
        $patch++
        $NewVersion = "$major.$minor.$patch"
        Write-Host "Auto-incremented to: $NewVersion" -ForegroundColor Green
    } else {
        $NewVersion = $userInput
    }
}

# Get new version code if not provided
if ($NewVersionCode -eq 0) {
    $suggestedCode = $currentVersionCode + 1
    Write-Host "Enter new version code (current: $currentVersionCode, suggested: $suggestedCode):" -ForegroundColor Yellow
    $userInput = Read-Host
    if ([string]::IsNullOrEmpty($userInput)) {
        $NewVersionCode = $suggestedCode
    } else {
        $NewVersionCode = [int]$userInput
    }
}

# Validate version code
if ($NewVersionCode -le $currentVersionCode) {
    Write-Host "ERROR: New version code ($NewVersionCode) must be higher than current ($currentVersionCode)" -ForegroundColor Red
    Write-Host "Play Store requires version code to increase with each release." -ForegroundColor Red
    exit 1
}

# Confirm update
$newVersionString = "$NewVersion+$NewVersionCode"
Write-Host ""
Write-Host "New version will be: $newVersionString" -ForegroundColor Cyan
Write-Host "  Version Name: $NewVersion" -ForegroundColor Cyan
Write-Host "  Version Code: $NewVersionCode" -ForegroundColor Cyan
Write-Host ""
Write-Host "Continue? (Y/N):" -ForegroundColor Yellow
$confirm = Read-Host
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Update cancelled." -ForegroundColor Yellow
    exit 0
}

# Update pubspec.yaml
Write-Host ""
Write-Host "Updating pubspec.yaml..." -ForegroundColor Yellow
$newPubspecContent = $pubspecContent -replace "version:\s*$currentVersion", "version: $newVersionString"
Set-Content -Path "pubspec.yaml" -Value $newPubspecContent -NoNewline
Write-Host "✓ Version updated to $newVersionString" -ForegroundColor Green
Write-Host ""

# Ask if user wants to build
Write-Host "Build new AAB now? (Y/N):" -ForegroundColor Yellow
$buildNow = Read-Host
if ($buildNow -eq "Y" -or $buildNow -eq "y") {
    Write-Host ""
    Write-Host "Building AAB..." -ForegroundColor Yellow
    Write-Host ""
    
    # Clean
    Write-Host "Cleaning previous builds..." -ForegroundColor Yellow
    flutter clean | Out-Null
    
    # Get dependencies
    Write-Host "Getting dependencies..." -ForegroundColor Yellow
    flutter pub get | Out-Null
    
    # Build
    Write-Host "Building release AAB..." -ForegroundColor Yellow
    Write-Host ""
    flutter build appbundle --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✓ Build Successful!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        $aabPath = "build\app\outputs\bundle\release\app-release.aab"
        if (Test-Path $aabPath) {
            $aabFile = Get-Item $aabPath
            $fileSize = [math]::Round($aabFile.Length / 1MB, 2)
            
            Write-Host "AAB File:" -ForegroundColor Cyan
            Write-Host "  Location: $((Get-Location).Path)\$aabPath" -ForegroundColor White
            Write-Host "  Size: $fileSize MB" -ForegroundColor Cyan
            Write-Host "  Version: $newVersionString" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Ready to upload to Play Store!" -ForegroundColor Green
        }
    } else {
        Write-Host ""
        Write-Host "ERROR: Build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "Version updated. Build manually when ready:" -ForegroundColor Yellow
    Write-Host "  flutter build appbundle --release" -ForegroundColor White
}

Write-Host ""
