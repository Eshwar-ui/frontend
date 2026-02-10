# Version Update Guide for Play Store

This guide helps you update your app version and upload a new release to the Play Store.

## ✅ Required Files Checklist

All required files are present and properly configured:

### 1. **Version Configuration** ✓
   - **File**: `pubspec.yaml`
   - **Current Version**: `1.0.1+3`
     - `1.0.1` = versionName (user-facing version)
     - `3` = versionCode (must be incremented for each Play Store upload)
   - **Status**: ✅ Configured

### 2. **Signing Configuration** ✓
   - **Keystore File**: `my-release-key.jks` ✓
   - **Key Properties**: `android/key.properties` ✓
     - Contains: storePassword, keyPassword, keyAlias, storeFile
   - **Status**: ✅ Configured

### 3. **Build Configuration** ✓
   - **File**: `android/app/build.gradle.kts`
   - **Package Name**: `com.quantumdashboard.app`
   - **Signing Config**: Configured to use keystore
   - **Version**: Automatically reads from `pubspec.yaml`
   - **Status**: ✅ Configured

### 4. **Android Manifest** ✓
   - **File**: `android/app/src/main/AndroidManifest.xml`
   - **App Label**: "Quantum Works Employee Dashboard"
   - **Package**: Configured via build.gradle.kts
   - **Status**: ✅ Configured

## 📋 Steps to Update Version

### Step 1: Update Version Number

Edit `pubspec.yaml` and update the version:

```yaml
version: 1.0.2+4  # Increment both versionName and versionCode
```

**Version Numbering Rules:**
- **versionName** (e.g., `1.0.2`): User-facing version (can be any format)
- **versionCode** (e.g., `4`): Must be **higher** than the previous version
  - If your last published version was `1.0.1+3`, the new versionCode must be `4` or higher
  - Play Store **rejects** uploads with same or lower versionCode

**Examples:**
- Current: `1.0.1+3` → New: `1.0.2+4` (recommended)
- Current: `1.0.1+3` → New: `1.0.1+4` (patch update, same versionName)
- Current: `1.0.1+3` → New: `1.1.0+4` (minor update)
- Current: `1.0.1+3` → New: `2.0.0+4` (major update)

### Step 2: Build New AAB

Run the build script:
```powershell
cd frontend
.\build_release.ps1
```

Or manually:
```powershell
cd frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

### Step 3: Verify AAB File

The new AAB will be at:
```
frontend\build\app\outputs\bundle\release\app-release.aab
```

**Important Checks:**
- ✅ File exists
- ✅ File size < 150MB
- ✅ Version code is higher than previous version

### Step 4: Upload to Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app: **Quantum Works Employee Dashboard**
3. Navigate to **Production** → **Releases** (or **Testing** → **Internal/Closed/Open testing**)
4. Click **Create new release**
5. Upload the new `app-release.aab` file
6. Add **Release notes** describing what's new:
   ```
   What's new in this version:
   - Bug fixes
   - Performance improvements
   - New features
   ```
7. Click **Save**
8. Click **Review release**
9. Click **Start rollout to Production** (or appropriate track)

## 🔍 Quick Version Check

To check your current version:
```powershell
cd frontend
Select-String -Path "pubspec.yaml" -Pattern "version:"
```

## ⚠️ Important Notes

### Version Code Requirements
- **MUST** be higher than the last published version
- **CANNOT** be the same or lower
- Play Store will **reject** uploads with invalid versionCode

### Keystore Security
- **NEVER** lose `my-release-key.jks`
- **NEVER** lose passwords in `key.properties`
- **ALWAYS** use the same keystore for updates
- Without the original keystore, you **cannot** update your app

### Package Name
- **DO NOT** change `com.quantumdashboard.app`
- Changing package name creates a **new app** (not an update)
- Package name is set in `android/app/build.gradle.kts`

### Testing Before Production
Consider testing in **Internal testing** track first:
1. Upload to Internal testing
2. Test with your team
3. Promote to Production when ready

## 🚨 Troubleshooting

### Error: "Version code has already been used"
- **Solution**: Increment versionCode in `pubspec.yaml`
- Check your last published versionCode in Play Console

### Error: "Upload failed: Invalid keystore"
- **Solution**: Ensure `my-release-key.jks` and `key.properties` are correct
- Verify passwords match the original keystore

### Error: "Package name mismatch"
- **Solution**: Ensure package name is exactly `com.quantumdashboard.app`
- Check `android/app/build.gradle.kts` → `applicationId`

## 📝 Version History Template

Keep track of your versions:

```
Version 1.0.1+3 (Published: [Date])
- Initial release

Version 1.0.2+4 (Published: [Date])
- [List changes here]

Version 1.1.0+5 (Published: [Date])
- [List changes here]
```

## ✅ Pre-Upload Checklist

Before uploading to Play Store:

- [ ] Version updated in `pubspec.yaml`
- [ ] versionCode is higher than previous version
- [ ] AAB file built successfully
- [ ] AAB file size < 150MB
- [ ] Release notes prepared
- [ ] Tested on device/emulator
- [ ] Keystore file secure and accessible
- [ ] Package name unchanged (`com.quantumdashboard.app`)

---

**Ready to update?** Follow Steps 1-4 above! 🚀
