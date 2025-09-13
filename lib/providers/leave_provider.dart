import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/services/leave_service.dart';

class LeaveProvider with ChangeNotifier {
  final LeaveService _leaveService = LeaveService();

  List<Leave> _leaves = [];
  bool _isLoading = false;
  String? _error;

  List<Leave> get leaves => _leaves;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getMyLeaves(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaves = await _leaveService.getMyLeaves(employeeId);
    } catch (e, stack) {
      print("Error in LeaveProvider.getMyLeaves: $e");
      print(stack);
      _error = e.toString();
    } finally {
      _isLoading = false;
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
    } catch (e, stack) {
      print("Error in LeaveProvider.getAllLeaves: $e");
      print(stack);
      _error = e.toString();
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
  Future<void> updateLeave(String employeeId, String leaveId, Map<String, dynamic> leaveData) async {
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
