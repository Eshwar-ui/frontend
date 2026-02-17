import 'dart:convert';

import 'package:http/http.dart' as http;
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
}
