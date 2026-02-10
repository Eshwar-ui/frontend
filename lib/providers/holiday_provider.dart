import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/holiday_service.dart';

class HolidayProvider with ChangeNotifier {
  final HolidayService _holidayService = HolidayService();

  final Map<int, List<Holiday>> _holidayCache = {};
  bool _isLoading = false;
  String? _error;

  List<Holiday> get holidays =>
      _holidayCache.values.expand((list) => list).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to safely notify listeners after the current frame
  // This prevents setState() errors when notifyListeners() is called during build
  void _safeNotifyListeners() {
    // Use microtask to defer notification until after the current synchronous code
    // This ensures notifications don't happen during the build phase
    Future.microtask(() {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Get all holidays
  Future<void> getHolidays() async {
    print('HolidayProvider: Starting to fetch holidays...');
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final List<Holiday> holidaysList = await _holidayService.getHolidays();
      // Populate the _holidayCache by year
      _holidayCache.clear();
      for (final holiday in holidaysList) {
        final int year = DateTime.parse(holiday.date.toString()).year;
        _holidayCache.putIfAbsent(year, () => []).add(holiday);
      }
      print(
        'HolidayProvider: Successfully fetched ${holidaysList.length} holidays',
      );
    } catch (e) {
      print('HolidayProvider: Error fetching holidays: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Get holidays by year
  Future<void> getHolidaysByYear(int year) async {
    if (_holidayCache.containsKey(year)) {
      return; // Data is already cached
    }
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final newHolidays = await _holidayService.getHolidaysByYear(year);
      _holidayCache[year] = newHolidays;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
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
    _safeNotifyListeners();

    try {
      final result = await _holidayService.addHoliday(
        title: title,
        date: date,
        action: action,
      );

      // Normalize response: backend returns { message: "..." } on success
      // or throws ServerErrorException on error
      final normalizedResult = {
        'success': result['message'] != null && result['error'] == null,
        'message':
            result['message'] ??
            result['error'] ??
            'Holiday added successfully',
        'error': result['error'],
      };

      if (normalizedResult['success'] == true) {
        await getHolidays(); // Refresh the list
      }

      _isLoading = false;
      _safeNotifyListeners();
      return normalizedResult;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();

      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      return {'success': false, 'message': errorMessage, 'error': errorMessage};
    }
  }

  // Update holiday (Admin only)
  Future<Map<String, dynamic>> updateHoliday(
    String holidayId, {
    required String title,
    required String date,
    required String day,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _holidayService.updateHoliday(
        holidayId,
        title: title,
        date: date,
        day: day,
      );

      // Normalize response: backend returns { message: "..." } on success
      final normalizedResult = {
        'success': result['message'] != null && result['error'] == null,
        'message':
            result['message'] ??
            result['error'] ??
            'Holiday updated successfully',
        'error': result['error'],
      };

      if (normalizedResult['success'] == true) {
        await getHolidays(); // Refresh the list
      }

      _isLoading = false;
      _safeNotifyListeners();
      return normalizedResult;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();

      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      return {'success': false, 'message': errorMessage, 'error': errorMessage};
    }
  }

  // Delete holiday (Admin only)
  Future<Map<String, dynamic>> deleteHoliday(String holidayId) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _holidayService.deleteHoliday(holidayId);

      // Normalize response: backend returns { message: "..." } on success
      final normalizedResult = {
        'success': result['message'] != null && result['error'] == null,
        'message':
            result['message'] ??
            result['error'] ??
            'Holiday deleted successfully',
        'error': result['error'],
      };

      if (normalizedResult['success'] == true) {
        await getHolidays(); // Refresh the list
      }

      _isLoading = false;
      _safeNotifyListeners();
      return normalizedResult;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();

      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      return {'success': false, 'message': errorMessage, 'error': errorMessage};
    }
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
