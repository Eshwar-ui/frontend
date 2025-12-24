import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/services/api_service.dart';

class Department {
  final String id;
  final String department;
  final String designation;

  Department({
    required this.id,
    required this.department,
    required this.designation,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['_id'] ?? json['id'] ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'department': department, 'designation': designation};
  }
}

class DepartmentService extends ApiService {
  // Get all departments
  Future<List<Department>> getDepartments() async {
    final url = '${ApiService.baseUrl}/api/getDepartment';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);

    final data = handleResponse(response);
    final departments = (data as List)
        .map((json) => Department.fromJson(json))
        .toList();

    return departments;
  }

  // Add department
  Future<Map<String, dynamic>> addDepartment({
    required String department,
    required String designation,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/department'),
      headers: await getHeaders(),
      body: json.encode({'department': department, 'designation': designation}),
    );

    final data = handleResponse(response);
    return data;
  }
}
