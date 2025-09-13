import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/holiday_service.dart';

class HolidayProvider with ChangeNotifier {
  final HolidayService _holidayService = HolidayService();

  List<Holiday> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all holidays
  Future<void> getHolidays() async {
    print('HolidayProvider: Starting to fetch holidays...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _holidays = await _holidayService.getHolidays();
      print('HolidayProvider: Successfully fetched ${_holidays.length} holidays');
    } catch (e) {
      print('HolidayProvider: Error fetching holidays: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get holidays by year
  Future<void> getHolidaysByYear(int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _holidays = await _holidayService.getHolidaysByYear(year);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add holiday (Admin only)
  Future<Map<String, dynamic>> addHoliday({
    required String title,
    required String date,
    required String action,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _holidayService.addHoliday(
        title: title,
        date: date,
        action: action,
      );
      await getHolidays(); // Refresh the list
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update holiday (Admin only)
  Future<Map<String, dynamic>> updateHoliday(String holidayId, {
    required String title,
    required String date,
    required String day,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _holidayService.updateHoliday(holidayId, title: title, date: date, day: day);
      await getHolidays(); // Refresh the list
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete holiday (Admin only)
  Future<Map<String, dynamic>> deleteHoliday(String holidayId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _holidayService.deleteHoliday(holidayId);
      await getHolidays(); // Refresh the list
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
