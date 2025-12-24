import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
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
      // If API returns empty, load mock data for UI preview
      if (_leaves.isEmpty) {
        print("No leaves found, loading mock data for UI preview");
        _leaves = _getMockLeaves();
      }
    } catch (e, stack) {
      print("Error in LeaveProvider.getMyLeaves: $e");
      print(stack);
      _error = e.toString();
      // Load mock data for UI preview
      print("Loading mock data due to error");
      _leaves = _getMockLeaves();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force load mock data (for development/testing)
  void loadMockData() {
    print("Force loading mock data");
    _leaves = _getMockLeaves();
    _isLoading = false;
    notifyListeners();
  }

  // Mock data for UI preview
  List<Leave> _getMockLeaves() {
    final now = DateTime.now();
    return [
      Leave(
        id: 'mock1',
        employeeId: 'QWIT-1001',
        type: 'Sick Leave',
        from: now.subtract(Duration(days: 5)),
        to: now.subtract(Duration(days: 3)),
        reason: 'Feeling unwell, need rest',
        status: 'Approved',
        days: 3,
        actionBy: 'HR Manager',
        action: 'Approved by HR',
      ),
      Leave(
        id: 'mock2',
        employeeId: 'QWIT-1001',
        type: 'Personal Leave',
        from: now.add(Duration(days: 10)),
        to: now.add(Duration(days: 12)),
        reason: 'Family event',
        status: 'Pending',
        days: 3,
        actionBy: '-',
        action: '-',
      ),
      Leave(
        id: 'mock3',
        employeeId: 'QWIT-1001',
        type: 'Annual Leave',
        from: now.subtract(Duration(days: 30)),
        to: now.subtract(Duration(days: 25)),
        reason: 'Vacation',
        status: 'Approved',
        days: 6,
        actionBy: 'HR Manager',
        action: 'Approved',
      ),
    ];
  }

  Future<void> fetchLeaveTypes() async {
    try {
      final types = await _leaveService.getLeaveTypes();
      _leaveTypes = types;
      notifyListeners();
    } catch (e) {
      print('Error fetching leave types: $e');
      // Use mock leave types as fallback
      _leaveTypes = [
        'Sick Leave',
        'Personal Leave',
        'Annual Leave',
        'Emergency Leave',
        'Maternity Leave',
        'Paternity Leave',
      ];
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

  // Force load mock data for admin (for development/testing)
  void loadMockAllLeaves() {
    print("Force loading mock all leaves data");
    _leaves = _getMockAllLeaves();
    _isLoading = false;
    notifyListeners();
  }

  // Mock data for admin UI preview
  List<Leave> _getMockAllLeaves() {
    final now = DateTime.now();
    return [
      Leave(
        id: 'mock1',
        employeeId: 'QWIT-1002',
        type: 'Sick Leave',
        from: now.subtract(Duration(days: 2)),
        to: now,
        reason: 'Medical appointment',
        status: 'Pending',
        days: 3,
        actionBy: '-',
        action: '-',
        employee: Employee(
          id: 'emp1',
          employeeId: 'QWIT-1002',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john.doe@quantumworks.in',
          mobile: '9876543210',
          dateOfBirth: now.subtract(Duration(days: 30 * 365)),
          joiningDate: now.subtract(Duration(days: 365)),
          password: '',
          profileImage: '',
          department: 'Engineering',
          designation: 'Software Developer',
        ),
      ),
      Leave(
        id: 'mock2',
        employeeId: 'QWIT-1003',
        type: 'Personal Leave',
        from: now.add(Duration(days: 5)),
        to: now.add(Duration(days: 7)),
        reason: 'Personal work',
        status: 'Pending',
        days: 3,
        actionBy: '-',
        action: '-',
        employee: Employee(
          id: 'emp2',
          employeeId: 'QWIT-1003',
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane.smith@quantumworks.in',
          mobile: '9876543211',
          dateOfBirth: now.subtract(Duration(days: 28 * 365)),
          joiningDate: now.subtract(Duration(days: 200)),
          password: '',
          profileImage: '',
          department: 'Design',
          designation: 'UI/UX Designer',
        ),
      ),
      Leave(
        id: 'mock3',
        employeeId: 'QWIT-1004',
        type: 'Annual Leave',
        from: now.subtract(Duration(days: 15)),
        to: now.subtract(Duration(days: 10)),
        reason: 'Family vacation',
        status: 'Approved',
        days: 6,
        actionBy: 'Admin',
        action: 'Approved',
        employee: Employee(
          id: 'emp3',
          employeeId: 'QWIT-1004',
          firstName: 'Mike',
          lastName: 'Johnson',
          email: 'mike.johnson@quantumworks.in',
          mobile: '9876543212',
          dateOfBirth: now.subtract(Duration(days: 32 * 365)),
          joiningDate: now.subtract(Duration(days: 500)),
          password: '',
          profileImage: '',
          department: 'Marketing',
          designation: 'Marketing Manager',
        ),
      ),
      Leave(
        id: 'mock4',
        employeeId: 'QWIT-1005',
        type: 'Emergency Leave',
        from: now.subtract(Duration(days: 1)),
        to: now,
        reason: 'Family emergency',
        status: 'Rejected',
        days: 2,
        actionBy: 'Admin',
        action: 'Insufficient leave balance',
        employee: Employee(
          id: 'emp4',
          employeeId: 'QWIT-1005',
          firstName: 'Sarah',
          lastName: 'Williams',
          email: 'sarah.williams@quantumworks.in',
          mobile: '9876543213',
          dateOfBirth: now.subtract(Duration(days: 27 * 365)),
          joiningDate: now.subtract(Duration(days: 100)),
          password: '',
          profileImage: '',
          department: 'HR',
          designation: 'HR Executive',
        ),
      ),
    ];
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
