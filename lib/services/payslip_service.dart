import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class PayslipService extends ApiService {
  
  // Get payslips for specific employee
  Future<List<Payslip>> getPayslips(String empId, {int? month, int? year}) async {
    final queryParams = <String, String>{
      'empId': empId, // Always include empId
    };
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/payslips',
    ).replace(queryParameters: queryParams);

    final headers = await getHeaders();
    final response = await http.get(uri, headers: headers);

    final data = handleResponse(response);
    final payslips = (data as List).map((json) => Payslip.fromJson(json)).toList();
    
    return payslips;
  }

  // Get employee payslips (different from generated payslips)
  Future<List<EmployeePayslip>> getEmployeePayslips(String employeeId) async {
    final url = '${ApiService.baseUrl}/api/employee-payslip/$employeeId';
    final headers = await getHeaders();
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    final data = handleResponse(response);
    final employeePayslips = (data as List).map((json) => EmployeePayslip.fromJson(json)).toList();
    
    return employeePayslips;
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
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/generate-payslip'),
      headers: await getHeaders(),
      body: json.encode({
        'empId': empId,
        'month': month,
        'year': year,
        'basicSalary': basicSalary,
        'HRA': HRA,
        'TA': TA,
        'DA': DA,
        'conveyanceAllowance': conveyanceAllowance,
        'total': total,
        'employeesContributionPF': employeesContributionPF,
        'employersContributionPF': employersContributionPF,
        'professionalTAX': professionalTAX,
        'totalDeductions': totalDeductions,
        'NetSalary': NetSalary,
        'paidDays': paidDays,
        'LOPDays': LOPDays,
        'arrear': arrear,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Upload payslip
  Future<Map<String, dynamic>> uploadPayslip({
    required String employeeId,
    required String month,
    required String year,
    required String url,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/upload-payslip/'),
      headers: await getHeaders(),
      body: json.encode({
        'employeeId': employeeId,
        'month': month,
        'year': year,
        'url': url,
      }),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete employee payslip
  Future<Map<String, dynamic>> deleteEmployeePayslip(String payslipId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/delete-employeepayslip/$payslipId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete generated payslip
  Future<Map<String, dynamic>> deletePayslip(String payslipId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/delete-payslip/$payslipId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return data;
  }
}
