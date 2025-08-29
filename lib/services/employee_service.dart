import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class EmployeeService extends ApiService {
  
  // Get user profile
  Future<Employee> getProfile() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/employee/profile'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return Employee.fromJson(data);
  }

  // Update profile
  Future<Employee> updateProfile(Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/employee/profile'),
      headers: await getHeaders(),
      body: json.encode(updates),
    );

    final data = handleResponse(response);
    return Employee.fromJson(data);
  }

  // Admin Methods

  // Get all employees (Admin only)
  Future<List<Employee>> getAllEmployees() async {
    List<String> endpoints = [
      '${ApiService.baseUrl}/api/admin/employees',
      '${ApiService.baseUrl}/api/employees',
      '${ApiService.baseUrl}/employees',
    ];

    for (String endpoint in endpoints) {
      try {
        print('Trying endpoint: $endpoint');
        
        final response = await http.get(
          Uri.parse(endpoint),
          headers: await getHeaders(),
        );

        print('Employee API Response Status: ${response.statusCode}');
        print('Employee API Response Body: ${response.body}');

        if (response.statusCode == 404) {
          print('Endpoint $endpoint not found, trying next...');
          continue;
        }

        final data = handleResponse(response);
        
        if (data is List) {
          print('Response is a direct list with ${data.length} items');
          List<Employee> employees = [];
          for (var item in data) {
            try {
              employees.add(Employee.fromJson(Map<String, dynamic>.from(item as Map)));
            } catch (e) {
              print('Error parsing employee item: $e');
              print('Item data: $item');
              // Continue processing other items
            }
          }
          return employees;
        } else if (data is Map && data.containsKey('employees')) {
          final employeesList = data['employees'] as List;
          print('Response has employees array with ${employeesList.length} items');
          List<Employee> employees = [];
          for (var item in employeesList) {
            try {
              employees.add(Employee.fromJson(Map<String, dynamic>.from(item as Map)));
            } catch (e) {
              print('Error parsing employee item: $e');
              print('Item data: $item');
              // Continue processing other items
            }
          }
          return employees;
        } else if (data is Map && data.containsKey('data')) {
          final employeesList = data['data'] as List;
          print('Response has data array with ${employeesList.length} items');
          List<Employee> employees = [];
          for (var item in employeesList) {
            try {
              employees.add(Employee.fromJson(Map<String, dynamic>.from(item as Map)));
            } catch (e) {
              print('Error parsing employee item: $e');
              print('Item data: $item');
              // Continue processing other items
            }
          }
          return employees;
        } else {
          print('Unexpected response format: ${data.runtimeType}');
          print('Response data: $data');
          // Try next endpoint
          continue;
        }
      } catch (e) {
        print('Error with endpoint $endpoint: $e');
        // Continue to next endpoint
      }
    }
    
    // If all endpoints failed
    throw Exception('Failed to load employees from any endpoint. Please check your backend API.');
  }

  // Add new employee (Admin only)
  Future<Employee> addEmployee({
    required String employeeId,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    required String department,
    required String designation,
    required DateTime joinDate,
    required double salary,
    required String phone,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/admin/employees'),
      headers: await getHeaders(),
      body: json.encode({
        'employeeId': employeeId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
        'department': department,
        'designation': designation,
        'joinDate': joinDate.toIso8601String(),
        'salary': salary,
        'phone': phone,
        'address': address,
        'isActive': true,
      }),
    );

    final data = handleResponse(response);
    
    if (data is Map && data.containsKey('employee')) {
      return Employee.fromJson(Map<String, dynamic>.from(data['employee'] as Map));
    } else if (data is Map) {
      return Employee.fromJson(Map<String, dynamic>.from(data));
    } else {
      throw Exception('Unexpected response format');
    }
  }

  // Update employee (Admin only)
  Future<Employee> updateEmployee(String employeeId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/admin/employees/$employeeId'),
      headers: await getHeaders(),
      body: json.encode(updates),
    );

    final data = handleResponse(response);
    
    if (data is Map && data.containsKey('employee')) {
      return Employee.fromJson(Map<String, dynamic>.from(data['employee'] as Map));
    } else if (data is Map) {
      return Employee.fromJson(Map<String, dynamic>.from(data));
    } else {
      throw Exception('Unexpected response format');
    }
  }

  // Delete employee (Admin only)
  Future<bool> deleteEmployee(String employeeId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/admin/employees/$employeeId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data['success'] == true || response.statusCode == 200;
  }
}
