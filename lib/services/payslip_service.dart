import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class PayslipService extends ApiService {
  // Get payslips for specific employee or all payslips
  Future<List<Payslip>> getPayslips(
    String? empId, {
    int? month,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (empId != null && empId.isNotEmpty) {
      queryParams['empId'] = empId;
    }
    if (month != null) queryParams['month'] = month.toString();
    if (year != null) queryParams['year'] = year.toString();

    final uri = Uri.parse(
      '${ApiService.baseUrl}/api/payslips',
    ).replace(queryParameters: queryParams);

    final headers = await getHeaders();
    final response = await sendRequest(http.get(uri, headers: headers));

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    final payslips = rawList.map((json) => Payslip.fromJson(json)).toList();

    return payslips;
  }

  // Get employee payslips (different from generated payslips)
  Future<List<EmployeePayslip>> getEmployeePayslips(String employeeId) async {
    final url = '${ApiService.baseUrl}/api/employee-payslip/$employeeId';
    final headers = await getHeaders();

    final response = await sendRequest(
      http.get(Uri.parse(url), headers: headers),
    );

    final data = handleResponse(response);
    final rawList = data is List ? data : const [];
    final employeePayslips = rawList
        .map((json) => EmployeePayslip.fromJson(json))
        .toList();

    return employeePayslips;
  }

  // Generate payslip (Admin only)
  Future<Map<String, dynamic>> generatePayslip({
    required String empId,
    required int month,
    required int year,
    required double basicSalary,
    required double hra,
    required double ta,
    required double da,
    required double conveyanceAllowance,
    required double total,
    required double employeesContributionPF,
    required double employersContributionPF,
    required double professionalTAX,
    required double totalDeductions,
    required double netSalary,
    required int paidDays,
    required int lopDays,
    required double arrear,
  }) async {
    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/generate-payslip'),
        headers: await getHeaders(),
        body: json.encode({
          'empId': empId,
          'month': month,
          'year': year,
          'basicSalary': basicSalary,
          'HRA': hra,
          'TA': ta,
          'DA': da,
          'conveyanceAllowance': conveyanceAllowance,
          'total': total,
          'employeesContributionPF': employeesContributionPF,
          'employersContributionPF': employersContributionPF,
          'professionalTAX': professionalTAX,
          'totalDeductions': totalDeductions,
          'NetSalary': netSalary,
          'paidDays': paidDays,
          'LOPDays': lopDays,
          'arrear': arrear,
        }),
      ),
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
    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/upload-payslip/'),
        headers: await getHeaders(),
        body: json.encode({
          'employeeId': employeeId,
          'month': month,
          'year': year,
          'url': url,
        }),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete employee payslip
  Future<Map<String, dynamic>> deleteEmployeePayslip(String payslipId) async {
    final response = await sendRequest(
      http.delete(
        Uri.parse(
          '${ApiService.baseUrl}/api/delete-employeepayslip/$payslipId',
        ),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Delete generated payslip
  Future<Map<String, dynamic>> deletePayslip(String payslipId) async {
    final response = await sendRequest(
      http.delete(
        Uri.parse('${ApiService.baseUrl}/api/delete-payslip/$payslipId'),
        headers: await getHeaders(),
      ),
    );

    final data = handleResponse(response);
    return data;
  }

  // Bulk generate payslips (Admin)
  Future<Map<String, dynamic>> bulkGeneratePayslips(
    List<Map<String, dynamic>> rows,
  ) async {
    final normalizedRows = rows.map((row) {
      final month = row['month'];
      final year = row['year'];
      final paidDays = row['paidDays'];
      final lopDays = row['lopDays'];

      return {
        'empId': row['empId'],
        'month': month is int ? month : int.tryParse(month.toString()) ?? 0,
        'year': year is int ? year : int.tryParse(year.toString()) ?? 0,
        'basicSalary': (row['basicSalary'] ?? 0).toDouble(),
        'HRA': (row['hra'] ?? 0).toDouble(),
        'TA': (row['ta'] ?? 0).toDouble(),
        'DA': (row['da'] ?? 0).toDouble(),
        'conveyanceAllowance': (row['conveyanceAllowance'] ?? 0).toDouble(),
        'total': (row['total'] ?? 0).toDouble(),
        'employeesContributionPF': (row['employeesContributionPF'] ?? 0)
            .toDouble(),
        'employersContributionPF': (row['employersContributionPF'] ?? 0)
            .toDouble(),
        'professionalTAX': (row['professionalTAX'] ?? 0).toDouble(),
        'totalDeductions': (row['totalDeductions'] ?? 0).toDouble(),
        'NetSalary': (row['netSalary'] ?? 0).toDouble(),
        'paidDays': paidDays is int
            ? paidDays
            : int.tryParse(paidDays.toString()) ?? 0,
        'LOPDays': lopDays is int
            ? lopDays
            : int.tryParse(lopDays.toString()) ?? 0,
        'arrear': (row['arrear'] ?? 0).toDouble(),
      };
    }).toList();

    final response = await sendRequest(
      http.post(
        Uri.parse('${ApiService.baseUrl}/api/generate-payslip-bulk'),
        headers: await getHeaders(),
        body: json.encode({'rows': normalizedRows}),
      ),
    );

    final data = handleResponse(response);
    return data is Map<String, dynamic> ? data : {'results': data};
  }
}
