import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/utils/api_endpoints.dart';
import '../utils/app_logger.dart';

class LeaveService extends ApiService {
  // Apply for leave
  Future<Map<String, dynamic>> applyLeave({
    required String employeeId,
    required String leaveType,
    required DateTime from,
    required DateTime to,
    required String reason,
    String? compoffCreditId,
  }) async {
    final dateFormatter = DateFormat("yyyy-MM-dd");
    final days = to.difference(from).inDays + 1; // inclusive

    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/apply-leave'),
        headers: await getHeaders(),
        body: json.encode({
          'employeeId': employeeId,
          'leaveType': leaveType,
          'from': dateFormatter.format(from),
          'to': dateFormatter.format(to),
          'reason': reason,
          'days': days,
          if (compoffCreditId != null) 'compoffCreditId': compoffCreditId,
        }),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Get my leaves
  Future<List<Leave>> getMyLeaves(String employeeId) async {
    AppLogger.debug('LeaveService: Fetching leaves for employee', {
      'employeeId': employeeId,
      'url': '${ApiService.baseUrl}/api/get-leaves/$employeeId',
    });

    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/get-leaves/$employeeId'),
        headers: await getHeaders(),
      ),
    );

    AppLogger.debug('LeaveService: Response received', {
      'statusCode': response.statusCode,
      'employeeId': employeeId,
    });

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    final leaves = rawList.map((json) => Leave.fromJson(json)).toList();
    AppLogger.info('LeaveService: Successfully fetched leaves', {
      'employeeId': employeeId,
      'count': leaves.length,
    });
    return leaves;
  }

  // Get all leaves (Admin only)
  Future<List<Leave>> getAllLeaves() async {
    AppLogger.debug('LeaveService: Fetching all leaves', {
      'url': '${ApiService.baseUrl}/api/all-leaves',
    });

    // Check if we have a token
    final token = await getToken();
    if (token == null || token.isEmpty) {
      AppLogger.warning('LeaveService: No token found, cannot fetch leaves');
      throw Exception('Authentication required. Please login again.');
    }

    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/all-leaves'),
        headers: await getHeaders(),
      ),
    );

    AppLogger.debug('LeaveService: Response received', {
      'statusCode': response.statusCode,
    });

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    final leaves = rawList.map((json) => Leave.fromJson(json)).toList();
    AppLogger.info('LeaveService: Successfully fetched all leaves', {
      'count': leaves.length,
    });
    return leaves;
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
    final response = await sendRequest(
      http.put(
        Uri.parse('${ApiService.baseUrl}/api/leave/update-status'),
        headers: await getHeaders(),
        body: json.encode({'leaveId': leaveId, 'status': status}),
      ),
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
    final response = await sendRequest(
      http.put(
        Uri.parse('${ApiService.baseUrl}/api/update-leave/$employeeId/$leaveId'),
        headers: await getHeaders(),
        body: json.encode({'data': leaveData}),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Get specific leave (Employee)
  Future<Leave> getLeave(String employeeId, String leaveId) async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}/api/get-leave/$employeeId/$leaveId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return Leave.fromJson(data);
  }

  // Delete leave (Employee)
  Future<Map<String, dynamic>> deleteLeave(
    String employeeId,
    String leaveId,
  ) async {
    final response = await sendRequest(
      http.delete(
        Uri.parse('${ApiService.baseUrl}/api/delete-leave/$employeeId/$leaveId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Fetch available leave types from backend
  Future<List<String>> getLeaveTypes() async {
    final response = await sendRequest(
      http.get(
        Uri.parse('${ApiService.baseUrl}${ApiEndpoints.getLeaveTypes}'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    // Expecting an array of objects with 'leaveType' field
    if (data is List) {
      final types = data
          .map(
            (e) => (e is Map && e['leaveType'] != null)
                ? e['leaveType'].toString()
                : null,
          )
          .whereType<String>()
          .toList();
      if (!types.any((t) => t.toUpperCase() == 'COMPOFF')) {
        types.add('COMPOFF');
      }
      return types;
    }
    return <String>['COMPOFF'];
  }
}
