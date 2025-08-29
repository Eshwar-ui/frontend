import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class HolidayService extends ApiService {
  
  // Get all holidays
  Future<List<Holiday>> getHolidays() async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/holidays');
    
    final response = await http.get(uri, headers: await getHeaders());

    final data = handleResponse(response);
    
    // The API returns a list directly
    if (data is List) {
      List<Holiday> holidays = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          holidays.add(Holiday.fromJson(item));
        }
      }
      return holidays;
    } else {
      throw Exception('Expected List but got ${data.runtimeType}');
    }
  }

  // Get holidays by year (filtered on client side)
  Future<List<Holiday>> getHolidaysByYear(int year) async {
    final allHolidays = await getHolidays();
    return allHolidays.where((holiday) => holiday.year == year).toList();
  }

  // Add holiday (Admin only)
  Future<Holiday> addHoliday({
    required String holidayName,
    required String date,
    required String day,
    required String postBy,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/holidays'),
      headers: await getHeaders(),
      body: json.encode({
        'Holiday Name': holidayName,
        'Date': date,
        'Day': day,
        'Post By': postBy,
      }),
    );

    final data = handleResponse(response);
    if (data is Map<String, dynamic> && data.containsKey('holiday')) {
      return Holiday.fromJson(data['holiday'] as Map<String, dynamic>);
    } else {
      throw Exception('Unexpected response format for add holiday');
    }
  }

  // Update holiday (Admin only)
  Future<Holiday> updateHoliday(String holidayId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/holidays/$holidayId'),
      headers: await getHeaders(),
      body: json.encode(updates),
    );

    final data = handleResponse(response);
    if (data is Map<String, dynamic> && data.containsKey('holiday')) {
      return Holiday.fromJson(data['holiday'] as Map<String, dynamic>);
    } else {
      throw Exception('Unexpected response format for update holiday');
    }
  }

  // Delete holiday (Admin only)
  Future<bool> deleteHoliday(String holidayId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/holidays/$holidayId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      return data['message'] != null;
    } else {
      throw Exception('Unexpected response format for delete holiday');
    }
  }
}