import 'package:flutter/foundation.dart';
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/services/payslip_service.dart';

class PayslipProvider with ChangeNotifier {
  final PayslipService _payslipService = PayslipService();

  List<Payslip> _payslips = [];
  List<EmployeePayslip> _employeePayslips = [];
  bool _isLoading = false;
  String? _error;

  List<Payslip> get payslips => _payslips;
  List<EmployeePayslip> get employeePayslips => _employeePayslips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get payslips for specific employee
  Future<void> getPayslips(String empId, {int? month, int? year}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _payslips = await _payslipService.getPayslips(empId, month: month, year: year);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get employee payslips (different from generated payslips)
  Future<void> getEmployeePayslips(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _employeePayslips = await _payslipService.getEmployeePayslips(employeeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate payslip (Admin only)
  Future<Map<String, dynamic>> generatePayslip({
    required String empId,
    required int month,
    required int year,
    required double basicSalary,
    required double HRA,
    required double TA,
    required double DA,
    required double conveyanceAllowance,
    required double total,
    required double employeesContributionPF,
    required double employersContributionPF,
    required double professionalTAX,
    required double totalDeductions,
    required double NetSalary,
    required int paidDays,
    required int LOPDays,
    required double arrear,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _payslipService.generatePayslip(
        empId: empId,
        month: month,
        year: year,
        basicSalary: basicSalary,
        HRA: HRA,
        TA: TA,
        DA: DA,
        conveyanceAllowance: conveyanceAllowance,
        total: total,
        employeesContributionPF: employeesContributionPF,
        employersContributionPF: employersContributionPF,
        professionalTAX: professionalTAX,
        totalDeductions: totalDeductions,
        NetSalary: NetSalary,
        paidDays: paidDays,
        LOPDays: LOPDays,
        arrear: arrear,
      );
      await getPayslips(empId); // Refresh the list
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

  // Upload payslip
  Future<Map<String, dynamic>> uploadPayslip({
    required String employeeId,
    required String month,
    required String year,
    required String url,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _payslipService.uploadPayslip(
        employeeId: employeeId,
        month: month,
        year: year,
        url: url,
      );
      await getEmployeePayslips(employeeId); // Refresh the list
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

  // Delete employee payslip
  Future<Map<String, dynamic>> deleteEmployeePayslip(String payslipId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _payslipService.deleteEmployeePayslip(payslipId);
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

  // Delete generated payslip
  Future<Map<String, dynamic>> deletePayslip(String payslipId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _payslipService.deletePayslip(payslipId);
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
