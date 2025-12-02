import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<Attendance> _punches = [];
  final Map<String, List<Map<String, dynamic>>> _dateWiseCache = {};
  List<Map<String, dynamic>> _adminAttendance = [];
  bool _isLoading = false;
  String? _error;
  double _totalWorkingTime = 0.0;

  List<Attendance> get punches => _punches;
  List<Map<String, dynamic>> get dateWiseData =>
      _dateWiseCache.values.expand((list) => list).toList();
  List<Map<String, dynamic>> get adminAttendance => _adminAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalWorkingTime => _totalWorkingTime;

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

  // Punch in
  Future<Map<String, dynamic>> punchIn(
    String employeeId,
    String employeeName,
  ) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _attendanceService.punchIn(employeeId, employeeName);
      _isLoading = false;
      _safeNotifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Punch out
  Future<Map<String, dynamic>> punchOut(
    String employeeId,
    String employeeName,
  ) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _attendanceService.punchOut(
        employeeId,
        employeeName,
      );
      _isLoading = false;
      _safeNotifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get punches for specific employee
  Future<void> getPunches(
    String employeeId, {
    String? fromDate,
    int? month,
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final result = await _attendanceService.getPunches(
        employeeId,
        fromDate: fromDate,
        month: month,
        year: year,
      );
      _punches = result['punches'];
      _totalWorkingTime = result['totalWorkingTime'];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Get date-wise attendance data
  Future<void> getDateWiseData(
    String employeeId, {
    int? month,
    int? year,
    String? employeeName,
  }) async {
    final cacheKey = '${employeeId}_${year}_$month';
    if (_dateWiseCache.containsKey(cacheKey)) {
      return; // Data is already cached
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final newData = await _attendanceService.getDateWiseData(
        employeeId,
        month: month,
        year: year,
        employeeName: employeeName,
      );
      _dateWiseCache[cacheKey] = newData;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Get admin attendance data
  Future<void> getAdminAttendance({
    String? employee,
    int? month,
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _adminAttendance = await _attendanceService.getAdminAttendance(
        employee: employee,
        month: month,
        year: year,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Get employee activity for specific date (Admin)
  Future<Map<String, dynamic>> getEmployeeDatePunches(
    String employeeId,
    String date,
  ) async {
    try {
      return await _attendanceService.getEmployeeDatePunches(employeeId, date);
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      return {'punches': [], 'totalWorkingTime': 0.0};
    }
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
