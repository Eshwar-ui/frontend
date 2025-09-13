class Payslip {
  final String id;
  final String empId;
  final int month;
  final int year;
  final String payslipUrl;

  Payslip({
    required this.id,
    required this.empId,
    required this.month,
    required this.year,
    required this.payslipUrl,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      id: json['_id'] ?? json['id'] ?? '',
      empId: json['empId'] ?? '',
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      payslipUrl: json['payslipUrl'] ?? '',
    );
  }

  // Helper method to get month name
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Helper method to get formatted period
  String get period => '$monthName $year';
}

// Model for employee payslips (different from generated payslips)
class EmployeePayslip {
  final String id;
  final String employeeId;
  final String year;
  final String month;
  final String url;

  EmployeePayslip({
    required this.id,
    required this.employeeId,
    required this.year,
    required this.month,
    required this.url,
  });

  factory EmployeePayslip.fromJson(Map<String, dynamic> json) {
    return EmployeePayslip(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      year: json['year'] ?? '',
      month: json['month'] ?? '',
      url: json['url'] ?? '',
    );
  }

  // Helper method to get month name
  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthNum = int.tryParse(month) ?? 1;
    return months[monthNum - 1];
  }

  // Helper method to get formatted period
  String get period => '$monthName $year';
}