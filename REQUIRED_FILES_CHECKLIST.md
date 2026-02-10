# Required Files Checklist for Play Store Updates

This document lists all files required for updating your app version on the Play Store.

## ✅ All Required Files Present

### 1. Version Configuration
- **File**: `pubspec.yaml`
- **Location**: `frontend/pubspec.yaml`
- **Current Version**: `1.0.1+3`
- **Purpose**: Defines app version (versionName + versionCode)
- **Status**: ✅ Present
- **Action Required**: Update version number for new release

### 2. Keystore File (Signing Key)
- **File**: `my-release-key.jks`
- **Location**: `frontend/my-release-key.jks`
- **Purpose**: Signs the app for Play Store upload
- **Status**: ✅ Present
- **Action Required**: None (keep secure!)

### 3. Signing Configuration
- **File**: `key.properties`
- **Location**: `frontend/android/key.properties`
- **Contents**:
  ```
  storePassword=android
  keyPassword=android
  keyAlias=my-key-alias
  storeFile=my-release-key.jks
  ```
- **Purpose**: Configures keystore for signing
- **Status**: ✅ Present
- **Action Required**: None

### 4. Android Build Configuration
- **File**: `build.gradle.kts`
- **Location**: `frontend/android/app/build.gradle.kts`
- **Key Settings**:
  - Package Name: `com.quantumdashboard.app`
  - Version: Reads from `pubspec.yaml`
  - Signing: Configured to use keystore
- **Status**: ✅ Present and Configured
- **Action Required**: None

### 5. Android Manifest
- **File**: `AndroidManifest.xml`
- **Location**: `frontend/android/app/src/main/AndroidManifest.xml`
- **Key Settings**:
  - App Label: "Quantum Works Employee Dashboard"
  - Package: Configured via build.gradle.kts
  - Permissions: Configured
- **Status**: ✅ Present
- **Action Required**: None

## 📋 Files Summary

| File | Location | Required | Status |
|------|----------|----------|--------|
| Version Config | `pubspec.yaml` | ✅ Yes | ✅ Present |
| Keystore | `my-release-key.jks` | ✅ Yes | ✅ Present |
| Key Properties | `android/key.properties` | ✅ Yes | ✅ Present |
| Build Config | `android/app/build.gradle.kts` | ✅ Yes | ✅ Present |
| Android Manifest | `android/app/src/main/AndroidManifest.xml` | ✅ Yes | ✅ Present |

## 🔄 For Each New Version Update

### Files You MUST Update:
1. **`pubspec.yaml`** - Update version number
   - Format: `version: X.Y.Z+BUILD_NUMBER`
   - Example: `1.0.1+3` → `1.0.2+4`

### Files You MUST NOT Change:
1. **`my-release-key.jks`** - Keep the same keystore
2. **`android/key.properties`** - Keep the same signing config
3. **Package name** in `build.gradle.kts` - Must stay `com.quantumdashboard.app`

## 🚀 Quick Update Process

1. **Update version** in `pubspec.yaml`
2. **Build AAB**: `flutter build appbundle --release`
3. **Upload** to Play Console

## 📝 Current Configuration

- **Package Name**: `com.quantumdashboard.app`
- **Current Version**: `1.0.1+3`
- **Version Name**: `1.0.1`
- **Version Code**: `3`
- **Next Version Code**: Must be `4` or higher

## ⚠️ Critical Notes

1. **Keystore Security**
   - Never delete `my-release-key.jks`
   - Never change passwords without updating `key.properties`
   - Keep backups in secure location

2. **Version Code**
   - Must increase with each release
   - Play Store rejects same or lower versionCode

3. **Package Name**
   - Must remain `com.quantumdashboard.app`
   - Changing it creates a new app (not an update)

## ✅ Verification Commands

Check if all files exist:
```powershell
cd frontend
Test-Path "pubspec.yaml"
Test-Path "my-release-key.jks"
Test-Path "android/key.properties"
Test-Path "android/app/build.gradle.kts"
Test-Path "android/app/src/main/AndroidManifest.xml"
```

Check current version:
```powershell
Select-String -Path "pubspec.yaml" -Pattern "version:"
```

---

**All files are present and ready for version updates!** ✅
