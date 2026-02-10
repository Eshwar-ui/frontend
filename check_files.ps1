# Quick file check script for Play Store deployment

Write-Host "=== Required Files Status ===" -ForegroundColor Cyan
Write-Host ""

$files = @(
    @{Path="pubspec.yaml"; Name="Version Configuration"},
    @{Path="my-release-key.jks"; Name="Keystore File"},
    @{Path="android\key.properties"; Name="Signing Configuration"},
    @{Path="android\app\build.gradle.kts"; Name="Build Configuration"},
    @{Path="android\app\src\main\AndroidManifest.xml"; Name="Android Manifest"}
)

$allPresent = $true
foreach ($file in $files) {
    if (Test-Path $file.Path) {
        Write-Host "[OK] $($file.Name)" -ForegroundColor Green
        Write-Host "     $($file.Path)" -ForegroundColor Gray
    } else {
        Write-Host "[MISSING] $($file.Name)" -ForegroundColor Red
        Write-Host "          $($file.Path)" -ForegroundColor Gray
        $allPresent = $false
    }
}

Write-Host ""
Write-Host "Current version:" -ForegroundColor Yellow
$versionLine = Select-String -Path "pubspec.yaml" -Pattern "version:" | Select-Object -First 1
if ($versionLine) {
    Write-Host "  $($versionLine.Line.Trim())" -ForegroundColor Cyan
}

Write-Host ""
if ($allPresent) {
    Write-Host "All required files are present!" -ForegroundColor Green
    Write-Host "Ready for version update." -ForegroundColor Green
} else {
    Write-Host "Some files are missing!" -ForegroundColor Red
    Write-Host "Please ensure all files are present before building." -ForegroundColor Red
}
