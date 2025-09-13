import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class HolidayService extends ApiService {
  
  // Get all holidays
  Future<List<Holiday>> getHolidays() async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/get-holidays');
    print('HolidayService: Fetching holidays from: $uri');
    
    final response = await http.get(uri, headers: await getHeaders());
    print('HolidayService: Response status: ${response.statusCode}');
    print('HolidayService: Response body: ${response.body}');

    final data = handleResponse(response);
    print('HolidayService: Parsed data: $data');
    
    // The API returns a list directly
    if (data is List) {
      List<Holiday> holidays = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          holidays.add(Holiday.fromJson(item));
        }
      }
      print('HolidayService: Successfully parsed ${holidays.length} holidays');
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
  Future<Map<String, dynamic>> addHoliday({
    required String title,
    required String date,
    required String action,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/add-holiday'),
      headers: await getHeaders(),
      body: json.encode({
        'title': title,
        'date': date,
        'action': action,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Update holiday (Admin only)
  Future<Map<String, dynamic>> updateHoliday(String holidayId, {
    required String title,
    required String date,
    required String day,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/update-holiday/$holidayId'),
      headers: await getHeaders(),
      body: json.encode({
        'title': title,
        'date': date,
        'day': day,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete holiday (Admin only)
  Future<Map<String, dynamic>> deleteHoliday(String holidayId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/delete-holiday/$holidayId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data;
  }
}