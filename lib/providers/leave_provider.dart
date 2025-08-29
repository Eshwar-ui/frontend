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

  Future<void> getMyLeaves() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaves = await _leaveService.getMyLeaves();
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
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _leaveService.applyLeave(
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      await getMyLeaves();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
