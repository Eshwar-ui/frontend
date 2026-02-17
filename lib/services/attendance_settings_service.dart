import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/services/api_service.dart';

class AttendanceSettingsService extends ApiService {
  Future<bool> getLocationPunchInEnabled() async {
    final url = '${ApiService.baseUrl}/api/attendance-settings';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.get(Uri.parse(url), headers: headers),
    );

    final data = handleResponse(response);
    return data['locationPunchInEnabled'] == true;
  }

  Future<bool> updateLocationPunchInEnabled(bool enabled) async {
    final url = '${ApiService.baseUrl}/api/attendance-settings';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'locationPunchInEnabled': enabled,
        }),
      ),
    );

    final data = handleResponse(response);
    return data['locationPunchInEnabled'] == true;
  }
}
