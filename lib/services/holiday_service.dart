import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/utils/app_logger.dart';

class HolidayService extends ApiService {
  // Get all holidays
  Future<List<Holiday>> getHolidays() async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/get-holidays');
    AppLogger.debug('HolidayService: Fetching holidays', {'uri': uri.toString()});
    
    final response = await sendRequest(
      http.get(uri, headers: await getHeaders()),
    );
    AppLogger.debug('HolidayService: Response received', {
      'statusCode': response.statusCode,
    });

    final data = handleResponse(response);
    AppLogger.debug('HolidayService: Parsed holiday payload');
    
    // The API returns a list directly
    if (data is List) {
      List<Holiday> holidays = [];
      for (var item in data) {
        if (item is Map<String, dynamic>) {
          holidays.add(Holiday.fromJson(item));
        }
      }
      AppLogger.debug('HolidayService: Successfully parsed holidays', {
        'count': holidays.length,
      });
      return holidays;
    } else {
      return [];
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
    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/add-holiday'),
        headers: await getHeaders(),
        body: json.encode({
          'title': title,
          'date': date,
          'action': action,
        }),
      ),
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
    final response = await sendRequest(
      http.put(
        Uri.parse('${ApiService.baseUrl}/api/update-holiday/$holidayId'),
        headers: await getHeaders(),
        body: json.encode({
          'title': title,
          'date': date,
          'day': day,
        }),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete holiday (Admin only)
  Future<Map<String, dynamic>> deleteHoliday(String holidayId) async {
    final response = await sendRequest(
      http.delete(
        Uri.parse('${ApiService.baseUrl}/api/delete-holiday/$holidayId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data;
  }
}
