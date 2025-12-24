import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/employee_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _employeeService = EmployeeService();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = false;
  String? _error;

  List<Employee> get employees => _employees;
  Employee? get selectedEmployee => _selectedEmployee;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get individual employee
  Future<Employee?> getEmployee(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedEmployee = await _employeeService.getEmployee(employeeId);
      _isLoading = false;
      notifyListeners();
      return _selectedEmployee;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get all employees (Admin only)
  Future<void> getAllEmployees({
    String? employeeId,
    String? employeeName,
    String? designation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employees = await _employeeService.getAllEmployees(
        employeeId: employeeId,
        employeeName: employeeName,
        designation: designation,
      );
      // If API returns empty, load mock data for UI preview
      if (_employees.isEmpty) {
        print("No employees found, loading mock data for UI preview");
        _employees = _getMockEmployees();
      }
    } catch (e) {
      print("Error in EmployeeProvider.getAllEmployees: $e");
      _error = e.toString();
      // Load mock data for UI preview on any error
      print("Loading mock data due to error");
      _employees = _getMockEmployees();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force load mock data (for development/testing)
  void loadMockData() {
    print("Force loading mock employees data");
    _employees = _getMockEmployees();
    _isLoading = false;
    notifyListeners();
  }

  // Mock data for UI preview
  List<Employee> _getMockEmployees() {
    final now = DateTime.now();
    return [
      Employee(
        id: 'mock1',
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
        role: 'employee',
      ),
      Employee(
        id: 'mock2',
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
        role: 'employee',
      ),
      Employee(
        id: 'mock3',
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
        role: 'employee',
      ),
      Employee(
        id: 'mock4',
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
        role: 'hr',
      ),
      Employee(
        id: 'mock5',
        employeeId: 'QWIT-1006',
        firstName: 'David',
        lastName: 'Brown',
        email: 'david.brown@quantumworks.in',
        mobile: '9876543214',
        dateOfBirth: now.subtract(Duration(days: 35 * 365)),
        joiningDate: now.subtract(Duration(days: 800)),
        password: '',
        profileImage: '',
        department: 'Engineering',
        designation: 'Senior Developer',
        role: 'employee',
      ),
    ];
  }

  // Add new employee (Admin only)
  Future<Map<String, dynamic>> addEmployee(
    Map<String, dynamic> employeeData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.addEmployee(employeeData);
      await getAllEmployees(); // Refresh the list
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

  // Update employee (Admin only)
  Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.updateEmployee(id, updates);
      await getAllEmployees(); // Refresh the list
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

  // Delete employee (Admin only)
  Future<Map<String, dynamic>> deleteEmployee(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _employeeService.deleteEmployee(employeeId);
      await getAllEmployees(); // Refresh the list
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

  // Set selected employee
  void setSelectedEmployee(Employee? employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
