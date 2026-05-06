import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/services/api_service.dart';

class AttendanceSettings {
  final bool locationPunchInEnabled;
  final String attendanceTimezone;
  final String defaultShiftStartTime;
  final String defaultShiftEndTime;
  final int punchInGraceMinutes;
  final int punchOutGraceMinutes;
  final List<String> payslipAdminEmails;
  final List<String> offerAdminEmails;

  AttendanceSettings({
    required this.locationPunchInEnabled,
    required this.attendanceTimezone,
    required this.defaultShiftStartTime,
    required this.defaultShiftEndTime,
    required this.punchInGraceMinutes,
    required this.punchOutGraceMinutes,
    required this.payslipAdminEmails,
    required this.offerAdminEmails,
  });

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceSettings(
      locationPunchInEnabled: json['locationPunchInEnabled'] == true,
      attendanceTimezone:
          (json['attendanceTimezone'] ?? 'Asia/Kolkata').toString(),
      defaultShiftStartTime:
          (json['defaultShiftStartTime'] ?? '09:30').toString(),
      defaultShiftEndTime:
          (json['defaultShiftEndTime'] ?? '18:30').toString(),
      punchInGraceMinutes:
          (json['punchInGraceMinutes'] is int)
          ? json['punchInGraceMinutes'] as int
          : 15,
      punchOutGraceMinutes:
          (json['punchOutGraceMinutes'] is int)
          ? json['punchOutGraceMinutes'] as int
          : 15,
      payslipAdminEmails: (json['payslipAdminEmails'] is List)
          ? (json['payslipAdminEmails'] as List)
                .map((email) => email.toString().trim().toLowerCase())
                .where((email) => email.isNotEmpty)
                .toList()
          : const [],
      offerAdminEmails: (json['offerAdminEmails'] is List)
          ? (json['offerAdminEmails'] as List)
                .map((email) => email.toString().trim().toLowerCase())
                .where((email) => email.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class AttendanceSettingsService extends ApiService {
  Future<AttendanceSettings> getAttendanceSettings() async {
    final url = '${ApiService.baseUrl}/api/attendance-settings';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.get(Uri.parse(url), headers: headers),
    );

    final data = handleResponse(response);
    return AttendanceSettings.fromJson(Map<String, dynamic>.from(data));
  }

  Future<AttendanceSettings> updateAttendanceSettings({
    bool? locationPunchInEnabled,
    String? attendanceTimezone,
    String? defaultShiftStartTime,
    String? defaultShiftEndTime,
    int? punchInGraceMinutes,
    int? punchOutGraceMinutes,
    List<String>? payslipAdminEmails,
    List<String>? offerAdminEmails,
  }) async {
    final url = '${ApiService.baseUrl}/api/attendance-settings';
    final headers = await getHeaders();
    final body = <String, dynamic>{};
    if (locationPunchInEnabled != null) {
      body['locationPunchInEnabled'] = locationPunchInEnabled;
    }
    if (attendanceTimezone != null) {
      body['attendanceTimezone'] = attendanceTimezone;
    }
    if (defaultShiftStartTime != null) {
      body['defaultShiftStartTime'] = defaultShiftStartTime;
    }
    if (defaultShiftEndTime != null) {
      body['defaultShiftEndTime'] = defaultShiftEndTime;
    }
    if (punchInGraceMinutes != null) {
      body['punchInGraceMinutes'] = punchInGraceMinutes;
    }
    if (punchOutGraceMinutes != null) {
      body['punchOutGraceMinutes'] = punchOutGraceMinutes;
    }
    if (payslipAdminEmails != null) {
      body['payslipAdminEmails'] = payslipAdminEmails;
    }
    if (offerAdminEmails != null) {
      body['offerAdminEmails'] = offerAdminEmails;
    }

    final response = await sendRequest(
      http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      ),
    );

    final data = handleResponse(response);
    return AttendanceSettings.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> getLocationPunchInEnabled() async {
    final settings = await getAttendanceSettings();
    return settings.locationPunchInEnabled;
  }

  Future<bool> updateLocationPunchInEnabled(bool enabled) async {
    final settings = await updateAttendanceSettings(
      locationPunchInEnabled: enabled,
    );
    return settings.locationPunchInEnabled;
  }
}
