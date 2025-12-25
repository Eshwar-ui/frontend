import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/services/api_service.dart';

class LeaveType {
  final String id;
  final String leaveType;

  LeaveType({required this.id, required this.leaveType});

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['_id'] ?? json['id'] ?? '',
      leaveType: json['leaveType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'leaveType': leaveType};
  }
}

class LeaveTypeService extends ApiService {
  // Get all leave types
  Future<List<LeaveType>> getLeaveTypes() async {
    final url = '${ApiService.baseUrl}/api/getLeavetype';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);

    final data = handleResponse(response);
    final leaveTypes = (data as List)
        .map((json) => LeaveType.fromJson(json))
        .toList();

    return leaveTypes;
  }

  // Add leave type
  Future<Map<String, dynamic>> addLeaveType({required String leaveType}) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/leaveType'),
      headers: await getHeaders(),
      body: json.encode({'leaveType': leaveType}),
    );

    final data = handleResponse(response);
    return data;
  }

  // Update leave type
  Future<Map<String, dynamic>> updateLeaveType({
    required String id,
    required String leaveType,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/leaveType/$id'),
      headers: await getHeaders(),
      body: json.encode({'leaveType': leaveType}),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete leave type
  Future<Map<String, dynamic>> deleteLeaveType(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/leaveType/$id'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data;
  }
}
