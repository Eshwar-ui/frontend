import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/leave_model.dart';

import 'package:quantum_dashboard/services/leave_service.dart';
import '../utils/app_logger.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  List<Leave> _leaves = [];
  bool _isLoading = false;
  String? _error;
  List<String> _leaveTypes = [];

  List<Leave> get leaves => _leaves;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get leaveTypes => _leaveTypes;

  Future<void> getMyLeaves(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaves = await _leaveService.getMyLeaves(employeeId);
    } catch (e, stack) {
      AppLogger.error("Error in LeaveProvider.getMyLeaves: $e", e, stack);
      _error = e.toString();
      _leaves = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaveTypes() async {
    try {
      final types = await _leaveService.getLeaveTypes();
      _leaveTypes = types;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error fetching leave types: $e', e);
      _leaveTypes = [];
      notifyListeners();
    }
  }

  Future<void> applyLeave({
    required String employeeId,
    required String leaveType,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.applyLeave(
        employeeId: employeeId,
        leaveType: leaveType,
        from: from,
        to: to,
        reason: reason,
      );
      await getMyLeaves(employeeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all leaves (Admin only)
  Future<void> getAllLeaves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaves = await _leaveService.getAllLeaves();
      // If API returns empty, that's fine - just show empty list
      AppLogger.info('LeaveProvider: Fetched leaves from API', {
        'count': _leaves.length,
      });
    } catch (e, stack) {
      AppLogger.error('LeaveProvider: Error in getAllLeaves', e, stack);

      // Check if it's an authentication error
      final errorString = e.toString();
      if (errorString.contains('Authentication required') ||
          errorString.contains('Bearer token not found') ||
          errorString.contains('JWT token not found')) {
        _error = 'Authentication failed. Please login again.';
        _leaves = []; // Clear leaves on auth error
        AppLogger.warning('LeaveProvider: Authentication error');
      } else if (e.toString().contains('ServerErrorException')) {
        // For other server errors, show empty list and log the error
        AppLogger.warning(
          'LeaveProvider: Server error occurred, showing empty list',
        );
        _error = 'Unable to load leave requests. Please try again.';
        _leaves = [];
      } else {
        _error = errorString;
        _leaves = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update leave status (Admin only)
  Future<void> updateLeaveStatus(String leaveId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.updateLeaveStatus(leaveId, status);
      await getAllLeaves(); // Refresh the list
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update leave (Employee)
  Future<void> updateLeave(
    String employeeId,
    String leaveId,
    Map<String, dynamic> leaveData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.updateLeave(employeeId, leaveId, leaveData);
      await getMyLeaves(employeeId); // Refresh the list
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete leave (Employee)
  Future<void> deleteLeave(String employeeId, String leaveId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.deleteLeave(employeeId, leaveId);
      await getMyLeaves(employeeId); // Refresh the list
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get specific leave (Employee)
  Future<Leave?> getLeave(String employeeId, String leaveId) async {
    try {
      return await _leaveService.getLeave(employeeId, leaveId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
