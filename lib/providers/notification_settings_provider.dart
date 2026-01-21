import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsProvider with ChangeNotifier {
  // Default values
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _badgeEnabled = true;
  bool _attendanceNotifications = true;
  bool _leaveNotifications = true;
  bool _holidayNotifications = true;
  bool _payslipNotifications = true;
  bool _generalNotifications = true;
  int _pollingInterval = 30; // seconds

  // Keys for SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _badgeEnabledKey = 'badge_enabled';
  static const String _attendanceNotificationsKey = 'attendance_notifications';
  static const String _leaveNotificationsKey = 'leave_notifications';
  static const String _holidayNotificationsKey = 'holiday_notifications';
  static const String _payslipNotificationsKey = 'payslip_notifications';
  static const String _generalNotificationsKey = 'general_notifications';
  static const String _pollingIntervalKey = 'polling_interval';

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get badgeEnabled => _badgeEnabled;
  bool get attendanceNotifications => _attendanceNotifications;
  bool get leaveNotifications => _leaveNotifications;
  bool get holidayNotifications => _holidayNotifications;
  bool get payslipNotifications => _payslipNotifications;
  bool get generalNotifications => _generalNotifications;
  int get pollingInterval => _pollingInterval;

  NotificationSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      _badgeEnabled = prefs.getBool(_badgeEnabledKey) ?? true;
      _attendanceNotifications =
          prefs.getBool(_attendanceNotificationsKey) ?? true;
      _leaveNotifications = prefs.getBool(_leaveNotificationsKey) ?? true;
      _holidayNotifications = prefs.getBool(_holidayNotificationsKey) ?? true;
      _payslipNotifications = prefs.getBool(_payslipNotificationsKey) ?? true;
      _generalNotifications = prefs.getBool(_generalNotificationsKey) ?? true;
      _pollingInterval = prefs.getInt(_pollingIntervalKey) ?? 30;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled != value) {
      _notificationsEnabled = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_notificationsEnabledKey, value);
      } catch (e) {
        debugPrint('Error saving notification enabled: $e');
      }
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_soundEnabledKey, value);
      } catch (e) {
        debugPrint('Error saving sound enabled: $e');
      }
    }
  }

  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled != value) {
      _vibrationEnabled = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_vibrationEnabledKey, value);
      } catch (e) {
        debugPrint('Error saving vibration enabled: $e');
      }
    }
  }

  Future<void> setBadgeEnabled(bool value) async {
    if (_badgeEnabled != value) {
      _badgeEnabled = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_badgeEnabledKey, value);
      } catch (e) {
        debugPrint('Error saving badge enabled: $e');
      }
    }
  }

  Future<void> setAttendanceNotifications(bool value) async {
    if (_attendanceNotifications != value) {
      _attendanceNotifications = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_attendanceNotificationsKey, value);
      } catch (e) {
        debugPrint('Error saving attendance notifications: $e');
      }
    }
  }

  Future<void> setLeaveNotifications(bool value) async {
    if (_leaveNotifications != value) {
      _leaveNotifications = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_leaveNotificationsKey, value);
      } catch (e) {
        debugPrint('Error saving leave notifications: $e');
      }
    }
  }

  Future<void> setHolidayNotifications(bool value) async {
    if (_holidayNotifications != value) {
      _holidayNotifications = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_holidayNotificationsKey, value);
      } catch (e) {
        debugPrint('Error saving holiday notifications: $e');
      }
    }
  }

  Future<void> setPayslipNotifications(bool value) async {
    if (_payslipNotifications != value) {
      _payslipNotifications = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_payslipNotificationsKey, value);
      } catch (e) {
        debugPrint('Error saving payslip notifications: $e');
      }
    }
  }

  Future<void> setGeneralNotifications(bool value) async {
    if (_generalNotifications != value) {
      _generalNotifications = value;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_generalNotificationsKey, value);
      } catch (e) {
        debugPrint('Error saving general notifications: $e');
      }
    }
  }

  Future<void> setPollingInterval(int seconds) async {
    if (_pollingInterval != seconds) {
      _pollingInterval = seconds;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_pollingIntervalKey, seconds);
      } catch (e) {
        debugPrint('Error saving polling interval: $e');
      }
    }
  }
}
