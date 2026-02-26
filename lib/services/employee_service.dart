import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/utils/app_logger.dart';

class EmployeeService extends ApiService {
  // Get individual employee
  Future<Employee> getEmployee(String employeeId) async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/individualemployee/$employeeId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return Employee.fromJson(data);
  }

  // Admin Methods

  // Get all employees (Admin only)
  Future<List<Employee>> getAllEmployees({
    String? employeeId,
    String? employeeName,
    String? designation,
  }) async {
    final queryParams = <String, String>{};
    if (employeeId != null) queryParams['employeeId'] = employeeId;
    if (employeeName != null) queryParams['employeeName'] = employeeName;
    if (designation != null) queryParams['designation'] = designation;

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/all-employees',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await sendRequest(
      http.get(uri, headers: await getHeaders()),
    );

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    final employees = rawList.map((json) => Employee.fromJson(json)).toList();
    AppLogger.debug('EmployeeService: Parsed employees', {
      'count': employees.length,
    });

    return employees;
  }

  // Add new employee (Admin only)
  Future<Map<String, dynamic>> addEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/add-employee'),
        headers: await getHeaders(),
        body: json.encode(employeeData),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Update employee (Admin only)
  Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await sendRequest(
      http.put(
        Uri.parse('${ApiService.baseUrl}/api/update-employee/$id'),
        headers: await getHeaders(),
        body: json.encode(updates),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete employee (Admin only)
  Future<Map<String, dynamic>> deleteEmployee(String employeeId) async {
    final response = await sendRequest(
      http.delete(
        Uri.parse('${ApiService.baseUrl}/api/delete-employee/$employeeId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  Future<Map<String, dynamic>> createEmployeeWithOffer({
    required String name,
    required String email,
    required Uint8List offerBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/employees/create');
    final token = await getToken();

    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.files.add(
      http.MultipartFile.fromBytes(
        'offerLetter',
        offerBytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = handleResponse(response);
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  Future<Map<String, dynamic>> sendOfferLetter(
    String id, {
    String? subject,
    String? templateText,
    String? imageUrl,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/employees/send-offer/$id');
    final headers = await getHeaders();
    final payload = <String, dynamic>{};
    if (subject != null) payload['subject'] = subject;
    if (templateText != null) payload['templateText'] = templateText;
    if (imageUrl != null) payload['imageUrl'] = imageUrl;
    if (cc != null) payload['cc'] = cc;
    if (bcc != null) payload['bcc'] = bcc;

    Future<http.Response> makeRequest() {
      return sendRequest(
        http.post(
          uri,
          headers: headers,
          body: json.encode(payload),
        ),
        timeout: const Duration(seconds: 75),
      );
    }

    try {
      final response = await makeRequest();
      final data = handleResponse(response);
      return data is Map<String, dynamic> ? data : {'data': data};
    } catch (firstError) {
      final message = firstError.toString().toLowerCase();
      final shouldRetry =
          message.contains('timeout') ||
          message.contains('502') ||
          message.contains('bad gateway');

      if (!shouldRetry) rethrow;

      await Future.delayed(const Duration(seconds: 2));
      final response = await makeRequest();
      final data = handleResponse(response);
      return data is Map<String, dynamic> ? data : {'data': data};
    }
  }

  Future<Map<String, dynamic>> getOfferTemplate() async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/offers/template'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  Future<Map<String, dynamic>> updateOfferTemplate({
    required String subject,
    required String templateText,
    String? imageUrl,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    final body = <String, dynamic>{
      'subject': subject,
      'templateText': templateText,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (cc != null) 'cc': cc,
      if (bcc != null) 'bcc': bcc,
    };

    final response = await sendRequest(
      http.put(
        Uri.parse('${ApiService.baseUrl}/api/offers/template'),
        headers: await getHeaders(),
        body: json.encode(body),
      ),
    );

    final data = handleResponse(response);
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  Future<List<Map<String, dynamic>>> getOfferLetters() async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/offers'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> deleteOfferLetter(String id) async {
    final response = await sendRequest(
      http.delete(
        Uri.parse('${ApiService.baseUrl}/api/offers/$id'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data is Map<String, dynamic> ? data : {'data': data};
  }

  /// Fetches offer letter PDF bytes (admin only). Returns Uint8List or throws.
  Future<Uint8List> getOfferPdfBytes(String offerId) async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/offers/$offerId/pdf'),
        headers: await getHeaders(),
      ),
      timeout: const Duration(seconds: 30),
    );

    if (response.statusCode >= 400) {
      final body = response.body;
      String message = 'Unable to load offer letter.';
      try {
        final json = jsonDecode(body) as Map<String, dynamic>?;
        message = json?['error']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    return response.bodyBytes;
  }
}
