import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class LeaveService extends ApiService {
  // Apply for leave
  Future<Map<String, dynamic>> applyLeave({
    required String employeeId,
    required String leaveType,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    final dateFormatter = DateFormat("yyyy-MM-dd");
    final days = to.difference(from).inDays + 1; // inclusive

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/apply-leave'),
      headers: await getHeaders(),
      body: json.encode({
        'employeeId': employeeId,
        'leaveType': leaveType,
        'from': dateFormatter.format(from),
        'to': dateFormatter.format(to),
        'reason': reason,
        'days': days,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Get my leaves
  Future<List<Leave>> getMyLeaves(String employeeId) async {
    print('LeaveService: Fetching leaves for employee: $employeeId');
    print('LeaveService: API URL: ${ApiService.baseUrl}/api/get-leaves/$employeeId');
    
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/get-leaves/$employeeId'),
      headers: await getHeaders(),
    );

    print('LeaveService: Response status: ${response.statusCode}');
    print('LeaveService: Response body: ${response.body}');

    final data = handleResponse(response);
    print('LeaveService: Parsed data: $data');
    return (data as List).map((json) => Leave.fromJson(json)).toList();
  }

  // Get all leaves (Admin only)
  Future<List<Leave>> getAllLeaves() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/all-leaves'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return (data as List).map((json) => Leave.fromJson(json)).toList();
  }

  // Get all leave requests (Admin only) - simplified for admin screen
  Future<List<Leave>> getAllLeaveRequests() async {
    return await getAllLeaves();
  }

  // Update leave status (Admin only)
  Future<Map<String, dynamic>> updateLeaveStatus(
    String leaveId,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/leave/update-status'),
      headers: await getHeaders(),
      body: json.encode({
        'leaveId': leaveId,
        'status': status,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Update leave (Employee)
  Future<Map<String, dynamic>> updateLeave(
    String employeeId,
    String leaveId,
    Map<String, dynamic> leaveData,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/update-leave/$employeeId/$leaveId'),
      headers: await getHeaders(),
      body: json.encode({
        'data': leaveData,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Get specific leave (Employee)
  Future<Leave> getLeave(String employeeId, String leaveId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/get-leave/$employeeId/$leaveId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return Leave.fromJson(data);
  }

  // Delete leave (Employee)
  Future<Map<String, dynamic>> deleteLeave(String employeeId, String leaveId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/delete-leave/$employeeId/$leaveId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data;
  }
}
