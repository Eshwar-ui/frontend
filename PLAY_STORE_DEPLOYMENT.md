# Play Store Deployment Guide

This guide will help you deploy the Quantum Works Employee Dashboard to the Google Play Store.

## Prerequisites

1. **Google Play Console Account**
   - Create a Google Play Developer account at https://play.google.com/console
   - Pay the one-time $25 registration fee
   - Complete your developer profile

2. **App Information Ready**
   - App name: "Quantum Works Employee Dashboard"
   - Short description (80 characters max)
   - Full description (4000 characters max)
   - App icon (512x512 PNG, 32-bit)
   - Feature graphic (1024x500 PNG)
   - Screenshots (at least 2, up to 8)
     - Phone: 16:9 or 9:16, min 320px, max 3840px
     - Tablet: 7" or 10", min 320px, max 3840px

3. **Keystore File**
   - ✅ Already configured: `my-release-key.jks`
   - Keep this file secure! You'll need it for all future updates.

## Current App Configuration

- **Package Name**: `com.quantumdashboard.app`
- **Version**: `1.0.1+3` (versionName: 1.0.1, versionCode: 3)
- **Min SDK**: Configured via Flutter
- **Target SDK**: Configured via Flutter

## Step 1: Build the Release AAB

The Play Store requires an Android App Bundle (AAB) file, not an APK.

### Option A: Using the Build Script

Run the provided build script:
```bash
cd frontend
.\build_release.ps1
```

### Option B: Manual Build

```bash
cd frontend
flutter clean
flutter pub get
flutter build appbundle --release
```

The AAB file will be located at:
```
frontend\build\app\outputs\bundle\release\app-release.aab
```

## Step 2: Prepare Play Store Assets

Before uploading, prepare these assets:

### Required Assets:
1. **App Icon**: 512x512 PNG (32-bit, no transparency)
   - Location: `assets/app_logo.png` (you may need to resize)

2. **Feature Graphic**: 1024x500 PNG
   - Marketing banner shown on the Play Store listing

3. **Screenshots**: 
   - Phone screenshots (at least 2)
   - Tablet screenshots (optional but recommended)
   - You can take screenshots using:
     ```bash
     flutter run --release
     # Then use device screenshot or emulator
     ```

4. **Privacy Policy URL** (Required for Play Store)
   - You must have a publicly accessible privacy policy
   - Create one or host it on your website

## Step 3: Create App in Play Console

1. Go to https://play.google.com/console
2. Click "Create app"
3. Fill in:
   - **App name**: Quantum Works Employee Dashboard
   - **Default language**: English (or your preferred language)
   - **App or game**: App
   - **Free or paid**: Free (or Paid if applicable)
   - **Declarations**: Check all applicable boxes

## Step 4: Complete Store Listing

1. Navigate to **Store presence > Store listing**
2. Fill in:
   - **App name**: Quantum Works Employee Dashboard
   - **Short description** (80 chars): Brief description of your app
   - **Full description** (4000 chars): Detailed description
   - Upload app icon (512x512)
   - Upload feature graphic (1024x500)
   - Upload screenshots
   - **Privacy Policy URL**: Required
   - **Contact details**: Email, phone, website

## Step 5: Set Up App Content

1. Navigate to **Policy > App content**
2. Complete:
   - **Privacy Policy**: Add your privacy policy URL
   - **Data safety**: Declare what data you collect
   - **Target audience**: Select appropriate age group
   - **Content ratings**: Complete questionnaire

## Step 6: Configure App Access

1. Navigate to **Policy > App access**
2. Choose:
   - **All functionality available without restrictions** (if public app)
   - OR configure restricted access if needed

## Step 7: Upload AAB File

1. Navigate to **Production > Releases**
2. Click **Create new release**
3. Upload your `app-release.aab` file
4. Add **Release notes** (what's new in this version)
5. Click **Save**
6. Click **Review release**

## Step 8: Review and Submit

1. Review all sections:
   - ✅ Store listing complete
   - ✅ App content configured
   - ✅ Privacy policy added
   - ✅ AAB uploaded
   - ✅ Release notes added

2. Click **Start rollout to Production**
3. Your app will be reviewed by Google (can take 1-7 days)

## Step 9: Monitor Review Status

- Check **Dashboard** for review status
- Google may request changes or clarifications
- Once approved, your app will be live on the Play Store!

## Important Notes

### Version Management
- Each new release must have a higher `versionCode` than the previous
- Current version: `1.0.1+3` (versionCode: 3)
- Next release should be: `1.0.2+4` or `1.0.1+4`

To update version:
1. Edit `pubspec.yaml`:
   ```yaml
   version: 1.0.2+4  # versionName+versionCode
   ```
2. Rebuild AAB

### Keystore Security
- **NEVER lose your keystore file** (`my-release-key.jks`)
- **NEVER lose your passwords** (storePassword, keyPassword)
- Keep backups in secure locations
- Without the keystore, you cannot update your app on Play Store

### Testing Before Release
Consider creating an **Internal testing** track first:
1. Upload AAB to Internal testing
2. Add testers via email
3. Test thoroughly
4. Then promote to Production

### App Signing by Google Play
Google Play can manage your app signing key:
- **Recommended**: Let Google manage your signing key
- Upload AAB signed with upload key
- Google re-signs with app signing key
- More secure and easier key management

## Troubleshooting

### Build Errors
- Ensure Flutter is up to date: `flutter upgrade`
- Clean build: `flutter clean && flutter pub get`
- Check Android SDK is properly configured

### Upload Errors
- AAB file size should be < 150MB
- Check version code is higher than previous
- Ensure all required fields in Play Console are filled

### Review Rejections
- Common reasons: Missing privacy policy, incorrect permissions, content violations
- Address feedback and resubmit

## Support Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment/android)
- [Play Store Policies](https://play.google.com/about/developer-content-policy/)

---

**Good luck with your deployment! 🚀**
