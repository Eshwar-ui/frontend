import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/services/location_service.dart';

class AttendanceService extends ApiService {
  final LocationService _locationService = LocationService();

  // Punch in
  Future<Map<String, dynamic>> punchIn(
    String employeeId,
    String employeeName,
    double latitude,
    double longitude,
  ) async {
    await _validateLocation(latitude, longitude, employeeId);

    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/punchin'),
        headers: await getHeaders(),
        body: json.encode({
          'employeeId': employeeId,
          'employeeName': employeeName,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Punch out
  Future<Map<String, dynamic>> punchOut(
    String employeeId,
    String employeeName,
    double latitude,
    double longitude,
  ) async {
    await _validateLocation(latitude, longitude, employeeId);

    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/punchout'),
        headers: await getHeaders(),
        body: json.encode({
          'employeeId': employeeId,
          'employeeName': employeeName,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Validate location using API (checks both company and employee locations)
  Future<void> _validateLocation(
    double latitude,
    double longitude,
    String employeeId,
  ) async {
    try {
      final result = await _locationService.validateLocation(
        latitude: latitude,
        longitude: longitude,
        employeeId: employeeId,
      );

      if (result['valid'] != true) {
        final message = result['message'] ?? 
            'You are not at a valid office location to punch in or out.';
        throw Exception(message);
      }
    } catch (e) {
      // Re-throw if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      // Otherwise wrap in Exception
      throw Exception(
        'Location validation failed: ${e.toString()}',
      );
    }
  }

  // Get punches for specific employee
  Future<Map<String, dynamic>> getPunches(
    String employeeId, {
    String? fromDate,
    int? month,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/punches/$employeeId',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    print('AttendanceService: Fetching punches for employee: $employeeId');
    print('AttendanceService: API URL: $uri');

    final response = await sendRequest(
      http.get(uri, headers: await getHeaders()),
    );

    print('AttendanceService: Response status: ${response.statusCode}');
    print('AttendanceService: Response body: ${response.body}');

    final data = handleResponse(response);
    print('AttendanceService: Parsed data: $data');
    final punches = (data['punches'] as List?) ?? const [];
    print('AttendanceService: Number of punches: ${punches.length}');

    return {
      'punches': punches
          .map((json) => Attendance.fromJson(json))
          .toList(),
      'totalWorkingTime': data['totalWorkingTime'] ?? 0.0,
    };
  }

  // Get date-wise attendance data
  Future<List<Map<String, dynamic>>> getDateWiseData(
    String employeeId, {
    int? month,
    int? year,
    String? employeeName,
  }) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();
    if (employeeName != null) queryParams['employeeName'] = employeeName;

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/date-wise-data/$employeeId',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await sendRequest(
      http.get(uri, headers: await getHeaders()),
    );

    final data = handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  // Get admin attendance data
  Future<List<Map<String, dynamic>>> getAdminAttendance({
    String? employee,
    int? month,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (employee != null) queryParams['employee'] = employee;
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/admin/attendance',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await sendRequest(
      http.get(uri, headers: await getHeaders()),
    );

    final data = handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  // Get employee activity for specific date (Admin)
  Future<Map<String, dynamic>> getEmployeeDatePunches(
    String employeeId,
    String date,
  ) async {
    final response = await sendRequest(
      http.get(
        Uri.parse(
          '${ApiService.baseUrl}/api/admin/employee/date-punches/$employeeId/$date',
        ),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return {
      'punches': ((data['punches'] as List?) ?? const [])
          .map((json) => Attendance.fromJson(json))
          .toList(),
      'totalWorkingTime': data['totalWorkingTime'] ?? 0.0,
    };
  }
}
