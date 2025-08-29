import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class PayslipService extends ApiService {
  // Get my payslips
  Future<List<Payslip>> getMyPayslips() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/payslip/my-payslips'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return (data as List).map((json) => Payslip.fromJson(json)).toList();
  }

  // Get specific payslip
  Future<Payslip> getPayslip(String payslipId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/payslip/$payslipId'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return Payslip.fromJson(data);
  }

  // Generate payslip (Admin only)
  Future<Payslip> generatePayslip({
    required String employeeId,
    required int month,
    required int year,
    Map<String, double>? allowances,
    Map<String, double>? deductions,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/payslip/generate'),
      headers: await getHeaders(),
      body: json.encode({
        'employeeId': employeeId,
        'month': month,
        'year': year,
        if (allowances != null) 'allowances': allowances,
        if (deductions != null) 'deductions': deductions,
      }),
    );

    final data = handleResponse(response);
    return Payslip.fromJson(data['payslip']);
  }
}
