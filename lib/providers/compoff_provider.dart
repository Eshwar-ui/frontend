import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/compoff_credit_model.dart';
import 'package:quantum_dashboard/services/compoff_service.dart';
import 'package:quantum_dashboard/utils/app_logger.dart';

class CompoffProvider with ChangeNotifier {
  final CompoffService _compoffService = CompoffService();

  List<CompoffCredit> _credits = [];
  bool _isLoading = false;
  String? _error;

  List<CompoffCredit> get credits => _credits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Map<String, dynamic>> fetchEligible(String date, {bool includeAllEmployees = false}) async {
    try {
      return await _compoffService.getEligible(date, includeAllEmployees: includeAllEmployees);
    } catch (e, stack) {
      AppLogger.error('CompoffProvider: error fetching eligible', e, stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> grantCompoff({
    required List<String> employeeIds,
    required String earnedDate,
    String? earnedSource,
    int? expiryDays,
    bool allowWithoutAttendance = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _compoffService.grantCompoff(
        employeeIds: employeeIds,
        earnedDate: earnedDate,
        earnedSource: earnedSource,
        expiryDays: expiryDays,
        allowWithoutAttendance: allowWithoutAttendance,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyCredits({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _credits = await _compoffService.getMyCredits(status: status);
    } catch (e) {
      _error = e.toString();
      _credits = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<CompoffCredit>> fetchEmployeeCredits(String employeeId) async {
    return _compoffService.getEmployeeCredits(employeeId);
  }
}
