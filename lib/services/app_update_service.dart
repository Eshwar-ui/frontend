import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UpdateCheckResult {
  updateStarted,
  noUpdateAvailable,
  throttled,
  notSupported,
  playStoreInstallRequired,
  failed,
}

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;

  static const String _lastCheckKey = 'last_update_check_at';
  static const Duration _defaultInterval = Duration(hours: 24);

  bool _isChecking = false;

  Future<UpdateCheckResult> checkNow() {
    return checkForUpdateIfDue(force: true);
  }

  Future<UpdateCheckResult> checkForUpdateIfDue({bool force = false}) async {
    if (_isChecking) {
      return UpdateCheckResult.throttled;
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return UpdateCheckResult.notSupported;
    }

    _isChecking = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final lastCheckMs = prefs.getInt(_lastCheckKey);

      if (!force && lastCheckMs != null) {
        final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
        if (now.difference(lastCheck) < _defaultInterval) {
          return UpdateCheckResult.throttled;
        }
      }

      await prefs.setInt(_lastCheckKey, now.millisecondsSinceEpoch);

      final updateInfo = await InAppUpdate.checkForUpdate();
      final isUpdateAvailable =
          updateInfo.updateAvailability == UpdateAvailability.updateAvailable;

      if (!isUpdateAvailable) {
        return UpdateCheckResult.noUpdateAvailable;
      }

      if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        try {
          await InAppUpdate.completeFlexibleUpdate();
        } catch (e) {
          debugPrint('App update download not yet complete: $e');
        }
        return UpdateCheckResult.updateStarted;
      }

      return UpdateCheckResult.noUpdateAvailable;
    } on PlatformException catch (e) {
      // Common for sideloaded builds, missing Play Store, or Play services issues.
      debugPrint('Play Store update check skipped: ${e.code} ${e.message}');
      final message = (e.message ?? '').toLowerCase();
      final isAppNotOwned =
          message.contains('error_app_not_owned') ||
          message.contains('install error(-10)') ||
          message.contains('not owned');
      if (isAppNotOwned) {
        return UpdateCheckResult.playStoreInstallRequired;
      }
      return UpdateCheckResult.failed;
    } catch (e) {
      debugPrint('Unexpected app update error: $e');
      return UpdateCheckResult.failed;
    } finally {
      _isChecking = false;
    }
  }
}
