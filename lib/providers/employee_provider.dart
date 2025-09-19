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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
