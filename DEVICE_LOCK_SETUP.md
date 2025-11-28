# Device Lock Setup Guide

## Overview
The Quantum Dashboard app now supports device lock functionality with both **PIN** and **Biometric Authentication** (fingerprint/Face ID). This adds an extra layer of security to protect sensitive employee data.

## Features

### 🔒 PIN Authentication
- Create a secure 6-digit PIN
- Required to access the app when device lock is enabled
- PIN is stored securely using encrypted storage
- Change PIN anytime from settings

### 👆 Biometric Authentication
- Support for fingerprint, Face ID, and other biometric methods
- Quick and convenient authentication
- Falls back to PIN if biometric fails
- Can be enabled/disabled independently

## Setup Instructions

### For Users

#### 1. Enable Device Lock
1. Open the app and navigate to **Settings**
2. Scroll to the **Security** section
3. Toggle **Device Lock** ON
4. Create a 6-digit PIN when prompted
5. Re-enter the PIN to confirm
6. Device lock is now enabled!

#### 2. Enable Biometric Authentication (Optional)
1. Ensure Device Lock is already enabled
2. In Settings > Security, toggle **Fingerprint/Face ID** ON
3. Authenticate with your biometric when prompted
4. Biometric authentication is now active

#### 3. Change PIN
1. Go to Settings > Security
2. Tap on **Change PIN**
3. Enter your current PIN
4. Enter your new 6-digit PIN
5. Confirm the new PIN

#### 4. Disable Device Lock
1. Go to Settings > Security
2. Toggle **Device Lock** OFF
3. Confirm in the dialog
4. Your PIN and biometric settings will be removed

### How It Works
- When you open the app, you'll first see the splash screen
- If device lock is enabled, you'll be prompted to authenticate
- You can use either:
  - **PIN**: Enter your 6-digit PIN
  - **Biometric**: Use fingerprint/Face ID (if enabled)
- After successful authentication, you'll access the app normally

## For Developers

### Files Added/Modified

#### New Files:
1. **`lib/services/local_auth_service.dart`**
   - Handles all biometric and PIN operations
   - Secure PIN storage using flutter_secure_storage
   - Biometric availability checks

2. **`lib/providers/local_auth_provider.dart`**
   - State management for device lock
   - Manages PIN and biometric settings
   - Authentication state handling

3. **`lib/screens/pin_setup_screen.dart`**
   - UI for creating and changing PIN
   - PIN confirmation flow
   - Error handling

4. **`lib/screens/device_lock_screen.dart`**
   - Authentication screen shown at app launch
   - PIN entry with number pad
   - Biometric authentication option
   - Failed attempt tracking

#### Modified Files:
1. **`lib/main.dart`**
   - Added LocalAuthProvider to app providers

2. **`lib/screens/splashscreen.dart`**
   - Added device lock check before navigation
   - Shows device lock screen if enabled

3. **`lib/new_Screens/settings_page.dart`**
   - Added Security section
   - Device lock toggle
   - Biometric toggle
   - Change PIN option

4. **`pubspec.yaml`**
   - Added dependencies:
     - `local_auth: ^2.3.0`
     - `flutter_secure_storage: ^9.2.2`
     - `crypto: ^3.0.3`

5. **`android/app/src/main/AndroidManifest.xml`**
   - Added biometric permissions:
     - `USE_BIOMETRIC`
     - `USE_FINGERPRINT`

6. **`ios/Runner/Info.plist`**
   - Added Face ID usage description

### Technical Details

#### PIN Storage
- PINs are hashed using SHA-256 before storage
- Stored in encrypted secure storage (platform-specific)
- Never stored in plain text
- Automatically cleared when device lock is disabled

#### Biometric Authentication
- Uses platform-native biometric APIs
- Supports multiple biometric types:
  - Fingerprint (Android/iOS)
  - Face ID (iOS)
  - Iris (Samsung devices)
- Graceful fallback to PIN if biometric fails

#### Security Features
- Failed attempt tracking
- Lockout after 5 failed PIN attempts
- Secure storage with hardware encryption
- No biometric data stored on device (uses OS APIs)

### Testing

#### Test on Android:
```bash
cd frontend
flutter run -d android
```

#### Test on iOS:
```bash
cd frontend
flutter run -d ios
```

#### Test Scenarios:
1. ✅ Enable device lock with PIN
2. ✅ Authenticate with PIN
3. ✅ Enable biometric authentication
4. ✅ Authenticate with biometric
5. ✅ Change PIN
6. ✅ Disable device lock
7. ✅ Failed PIN attempts
8. ✅ Biometric fallback to PIN
9. ✅ App restart with device lock enabled
10. ✅ Theme switching with device lock screen

### Troubleshooting

#### Issue: Biometric option not showing
**Solution**: Check that:
- Device has biometric hardware
- Biometric is enrolled in device settings
- Permissions are granted in AndroidManifest.xml/Info.plist

#### Issue: "Target of URI doesn't exist" errors in IDE
**Solution**: These are IDE cache issues. Run:
```bash
flutter clean
flutter pub get
```

#### Issue: Authentication fails on Android
**Solution**: Ensure biometric permissions are in AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

#### Issue: Face ID not working on iOS
**Solution**: Check Info.plist has NSFaceIDUsageDescription:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We need Face ID or Touch ID to securely authenticate and access your account</string>
```

## Security Best Practices

### For Users:
1. Choose a unique PIN that's not easily guessable
2. Don't share your PIN with others
3. Enable biometric for faster authentication
4. Change your PIN regularly
5. Disable device lock if device is stolen (requires account access)

### For Developers:
1. Never log PINs or biometric data
2. Use secure storage for all sensitive data
3. Implement rate limiting for failed attempts
4. Test on multiple devices and OS versions
5. Keep security dependencies updated

## Future Enhancements

Potential improvements for future versions:
- [ ] Pattern lock option
- [ ] Custom PIN length (4-8 digits)
- [ ] Biometric-only mode (no PIN fallback)
- [ ] Auto-lock after inactivity
- [ ] Lock specific sections of the app
- [ ] Remote device lock/unlock via admin
- [ ] PIN recovery via email/SMS
- [ ] Security audit logs

## Support

For issues or questions:
1. Check this guide first
2. Review the code documentation
3. Test on a different device
4. Contact the development team

---

**Version**: 1.0.0
**Last Updated**: November 2024
**Author**: Quantum Works Development Team

