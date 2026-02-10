import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/services/api_service.dart';

class MobileAccessService extends ApiService {
  // Get mobile access status for a specific employee
  Future<Map<String, dynamic>> getMobileAccessStatus(String employeeId) async {
    final url = '${ApiService.baseUrl}/api/mobile-access/$employeeId';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    return handleResponse(response);
  }

  // Toggle mobile access for an employee
  Future<Map<String, dynamic>> toggleMobileAccess(
    String employeeId,
    bool enabled,
  ) async {
    final url = '${ApiService.baseUrl}/api/mobile-access/$employeeId';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'enabled': enabled, 'mobileAccessEnabled': enabled}),
      ),
    );
    return handleResponse(response);
  }

  // Get all employees with mobile access status (admin only)
  Future<List<Map<String, dynamic>>> getAllEmployeesMobileAccess() async {
    final url = '${ApiService.baseUrl}/api/mobile-access';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.get(Uri.parse(url), headers: headers),
    );
    final data = handleResponse(response);

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
