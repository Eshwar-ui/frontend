import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class AttendanceService extends ApiService {
  // Check in
  Future<Attendance> checkIn() async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/attendance/checkin'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return Attendance.fromJson(data['attendance']);
  }

  // Check out
  Future<Attendance> checkOut() async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/attendance/checkout'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return Attendance.fromJson(data['attendance']);
  }

  // Get my attendance
  Future<List<Attendance>> getMyAttendance({int? month, int? year}) async {
    final queryParams = <String, String>{};
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/attendance/my-attendance',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: await getHeaders());

    final data = handleResponse(response);
    return (data as List).map((json) => Attendance.fromJson(json)).toList();
  }

  // Get today's attendance
  Future<Attendance?> getTodayAttendance() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/attendance/today'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data.containsKey('_id') ? Attendance.fromJson(data) : null;
  }
}
