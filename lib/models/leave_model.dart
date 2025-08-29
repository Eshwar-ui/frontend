import 'package:quantum_dashboard/models/user_model.dart';

class Leave {
  final String id;
  final String employeeId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final int days;
  final DateTime createdAt;
  final String? rejectionReason;
  final String? adminComments;
  final Employee? employee;

  Leave({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.days,
    required this.createdAt,
    this.rejectionReason,
    this.adminComments,
    this.employee,
  });

  // Getter methods for compatibility with admin screen
  String get employeeName {
    if (employee != null) {
      return employee!.fullName;
    }
    // Fallback: try to extract name from employeeId if it's a string
    if (employeeId.isNotEmpty) {
      return 'Employee ID: $employeeId';
    }
    return 'Unknown Employee';
  }
  DateTime get fromDate => startDate;
  DateTime get toDate => endDate;
  DateTime get appliedDate => createdAt;
  int get totalDays => days;

  factory Leave.fromJson(Map<String, dynamic> json) {
    // Safe employee parsing
    Employee? employee;
    if (json['employeeId'] is Map) {
      try {
        final employeeJson = json['employeeId'] as Map<String, dynamic>;
        // Handle different id field names
        if (!employeeJson.containsKey('id') && employeeJson.containsKey('_id')) {
          employeeJson['id'] = employeeJson['_id'];
        }
        employee = Employee.fromJson(employeeJson);
      } catch (e) {
        print('Error parsing employee data: $e');
        employee = null;
      }
    }

    return Leave(
      id: json['_id'] ?? json['id'],
      employeeId: json['employeeId'] is String 
          ? json['employeeId'] 
          : (json['employeeId'] is Map ? json['employeeId']['_id'] ?? json['employeeId']['id'] : ''),
      leaveType: json['leaveType'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      days: json['days'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      rejectionReason: json['rejectionReason'],
      adminComments: json['adminComments'],
      employee: employee,
    );
  }
}
