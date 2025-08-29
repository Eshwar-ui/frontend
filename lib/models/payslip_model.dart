import 'package:quantum_dashboard/models/user_model.dart';

class Payslip {
  final String id;
  final String employeeId;
  final int month;
  final int year;
  final double basicSalary;
  final Map<String, double> allowances;
  final Map<String, double> deductions;
  final int workingDays;
  final double presentDays;
  final double leaveDays;
  final double grossSalary;
  final double netSalary;
  final Employee? employee;

  Payslip({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.workingDays,
    required this.presentDays,
    required this.leaveDays,
    required this.grossSalary,
    required this.netSalary,
    this.employee,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['_id'],
      employeeId: json['employeeId'] is String 
          ? json['employeeId'] 
          : json['employeeId']['_id'],
      month: json['month'],
      year: json['year'],
      basicSalary: json['basicSalary']?.toDouble() ?? 0.0,
      allowances: Map<String, double>.from(
        json['allowances']?.map((k, v) => MapEntry(k, v?.toDouble() ?? 0.0)) ?? {}
      ),
      deductions: Map<String, double>.from(
        json['deductions']?.map((k, v) => MapEntry(k, v?.toDouble() ?? 0.0)) ?? {}
      ),
      workingDays: json['workingDays'],
      presentDays: json['presentDays']?.toDouble() ?? 0.0,
      leaveDays: json['leaveDays']?.toDouble() ?? 0.0,
      grossSalary: json['grossSalary']?.toDouble() ?? 0.0,
      netSalary: json['netSalary']?.toDouble() ?? 0.0,
      employee: json['employeeId'] is Map 
          ? Employee.fromJson(json['employeeId']) 
          : null,
    );
  }
}