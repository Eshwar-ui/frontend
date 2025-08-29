import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class LeaveService extends ApiService {
  // Apply for leave
  Future<Leave> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final dateFormatter = DateFormat("yyyy-MM-dd");
    final days = endDate.difference(startDate).inDays + 1; // inclusive

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/leave/apply'),
      headers: await getHeaders(),
      body: json.encode({
        'leaveType': leaveType.toLowerCase(), // ✅ match backend enum
        'startDate': dateFormatter.format(startDate), // ✅ clean date format
        'endDate': dateFormatter.format(endDate),
        'reason': reason,
        'days': days, // ✅ required field
      }),
    );

    final data = handleResponse(response);
    return Leave.fromJson(data['leave']);
  }

  // Get my leaves
  Future<List<Leave>> getMyLeaves() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/leave/my-leaves'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);

    // Support both { "leaves": [...] } and direct list response
    final leavesJson = data is List ? data : data['leaves'];

    return (leavesJson as List).map((json) => Leave.fromJson(json)).toList();
  }

  // Get all leaves (Admin only)
  Future<Map<String, dynamic>> getAllLeaves({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/leave/all',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await getHeaders());

    final data = handleResponse(response);
    return {
      'leaves': (data['leaves'] as List)
          .map((json) => Leave.fromJson(json))
          .toList(),
      'totalPages': data['totalPages'],
      'currentPage': data['currentPage'],
      'total': data['total'],
    };
  }

  // Get all leave requests (Admin only) - simplified for admin screen
  Future<List<Leave>> getAllLeaveRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/leave/all'),
        headers: await getHeaders(),
      );

      final data = handleResponse(response);
      
      // Handle both paginated and direct list responses
      if (data is List) {
        List<Leave> leaves = [];
        for (var item in data) {
          try {
            leaves.add(Leave.fromJson(item));
          } catch (e) {
            print('Error parsing leave item: $e');
            print('Item data: $item');
            // Continue processing other items
          }
        }
        return leaves;
      } else if (data is Map && data.containsKey('leaves')) {
        final leavesList = data['leaves'] as List;
        List<Leave> leaves = [];
        for (var item in leavesList) {
          try {
            leaves.add(Leave.fromJson(item));
          } catch (e) {
            print('Error parsing leave item: $e');
            print('Item data: $item');
            // Continue processing other items
          }
        }
        return leaves;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      print('Error in getAllLeaveRequests: $e');
      throw Exception('Failed to load leave requests: $e');
    }
  }

  // Update leave status (Admin only)
  Future<Leave> updateLeaveStatus(
    String leaveId,
    String status,
    String? adminComments,
  ) async {
    final body = <String, dynamic>{
      'status': status,
      'adminComments': adminComments ?? '',
    };

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/leave/$leaveId/status'),
      headers: await getHeaders(),
      body: json.encode(body),
    );

    final data = handleResponse(response);
    
    if (data is Map && data.containsKey('leave')) {
      return Leave.fromJson(Map<String, dynamic>.from(data['leave'] as Map));
    } else if (data is Map) {
      return Leave.fromJson(Map<String, dynamic>.from(data));
    } else {
      throw Exception('Unexpected response format');
    }
  }
}
