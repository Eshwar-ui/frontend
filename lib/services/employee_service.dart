import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class EmployeeService extends ApiService {
  
  // Get individual employee
  Future<Employee> getEmployee(String employeeId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/individualemployee/$employeeId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return Employee.fromJson(data);
  }

  // Admin Methods

  // Get all employees (Admin only)
  Future<List<Employee>> getAllEmployees({String? employeeId, String? employeeName, String? designation}) async {
    final queryParams = <String, String>{};
    if (employeeId != null) queryParams['employeeId'] = employeeId;
    if (employeeName != null) queryParams['employeeName'] = employeeName;
    if (designation != null) queryParams['designation'] = designation;

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/all-employees',
    ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(uri, headers: await getHeaders());

    final data = handleResponse(response);
    return (data as List).map((json) => Employee.fromJson(json)).toList();
  }

  // Add new employee (Admin only)
  Future<Map<String, dynamic>> addEmployee(Map<String, dynamic> employeeData) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/add-employee'),
      headers: await getHeaders(),
      body: json.encode(employeeData),
    );

    final data = handleResponse(response);
    return data;
  }

  // Update employee (Admin only)
  Future<Map<String, dynamic>> updateEmployee(String id, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/update-employee/$id'),
      headers: await getHeaders(),
      body: json.encode(updates),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete employee (Admin only)
  Future<Map<String, dynamic>> deleteEmployee(String employeeId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/delete-employee/$employeeId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data;
  }
}
