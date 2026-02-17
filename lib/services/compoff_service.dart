import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/compoff_credit_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/utils/app_logger.dart';

class CompoffService extends ApiService {
  Future<Map<String, dynamic>> getEligible(String date, {bool includeAllEmployees = false}) async {
    final query = 'date=$date${includeAllEmployees ? '&includeAllEmployees=true' : ''}';
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/compoff/eligible?$query'),
        headers: await getHeaders(),
      ),
    );

    return handleResponse(response);
  }

  Future<Map<String, dynamic>> grantCompoff({
    required List<String> employeeIds,
    required String earnedDate,
    String? earnedSource,
    int? expiryDays,
    bool allowWithoutAttendance = false,
  }) async {
    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/compoff/grant'),
        headers: await getHeaders(),
        body: json.encode({
          'employeeIds': employeeIds,
          'earnedDate': earnedDate,
          if (earnedSource != null) 'earnedSource': earnedSource,
          if (expiryDays != null) 'expiryDays': expiryDays,
          if (allowWithoutAttendance) 'allowWithoutAttendance': true,
        }),
      ),
    );

    return handleResponse(response);
  }

  Future<List<CompoffCredit>> getMyCredits({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/compoff/credits$query'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    final credits = rawList.map((json) => CompoffCredit.fromJson(json)).toList();
    AppLogger.info('CompoffService: fetched credits', {
      'count': credits.length,
    });
    return credits;
  }

  Future<List<CompoffCredit>> getEmployeeCredits(String employeeId) async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/compoff/credits/$employeeId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    return rawList.map((json) => CompoffCredit.fromJson(json)).toList();
  }
}
