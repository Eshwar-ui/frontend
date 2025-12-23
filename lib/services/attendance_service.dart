import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/models/head_office_location_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class AttendanceService extends ApiService {
  static const double _allowedRadiusInMeters = 100;

  // Hardcoded allowed locations
  final List<HeadOfficeLocation> _allowedLocations = [
    HeadOfficeLocation(
      name: 'Head Office',
      address: 'Hyderabad',
      latitude: 17.4483265,
      longitude: 78.3919326,
    ),
    HeadOfficeLocation(
      name: 'Branch Office',
      address: 'Bangalore',
      latitude: 12.9716,
      longitude: 77.5946,
    ),
  ];

  // Punch in
  Future<Map<String, dynamic>> punchIn(
    String employeeId,
    String employeeName,
    double latitude,
    double longitude,
  ) async {
    _validateLocation(latitude, longitude);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/punchin'),
      headers: await getHeaders(),
      body: json.encode({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'latitude': latitude,
        'longitude': longitude,
      }),
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
    _validateLocation(latitude, longitude);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/punchout'),
      headers: await getHeaders(),
      body: json.encode({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  void _validateLocation(double latitude, double longitude) {
    if (_allowedLocations.isEmpty) {
      return;
    }

    for (final location in _allowedLocations) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        location.latitude,
        location.longitude,
      );
      if (distance <= _allowedRadiusInMeters) {
        return; // User is within the allowed radius of a location
      }
    }

    throw Exception(
      'You are not at a valid office location to punch in or out.',
    );
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

    final response = await http.get(uri, headers: await getHeaders());

    print('AttendanceService: Response status: ${response.statusCode}');
    print('AttendanceService: Response body: ${response.body}');

    final data = handleResponse(response);
    print('AttendanceService: Parsed data: $data');
    print(
      'AttendanceService: Number of punches: ${(data['punches'] as List).length}',
    );

    return {
      'punches': (data['punches'] as List)
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

    final response = await http.get(uri, headers: await getHeaders());

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

    final response = await http.get(uri, headers: await getHeaders());

    final data = handleResponse(response);
    return List<Map<String, dynamic>>.from(data);
  }

  // Get employee activity for specific date (Admin)
  Future<Map<String, dynamic>> getEmployeeDatePunches(
    String employeeId,
    String date,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiService.baseUrl}/api/admin/employee/date-punches/$employeeId/$date',
      ),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return {
      'punches': (data['punches'] as List)
          .map((json) => Attendance.fromJson(json))
          .toList(),
      'totalWorkingTime': data['totalWorkingTime'] ?? 0.0,
    };
  }
}
