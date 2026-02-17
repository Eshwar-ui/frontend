import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/utils/app_logger.dart';

class Leave {
  final String id;
  final String employeeId;
  final String type;
  final DateTime from;
  final DateTime to;
  final String reason;
  final String status;
  final int days;
  final String actionBy;
  final String action;
  final Employee? employee;

  Leave({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.from,
    required this.to,
    required this.reason,
    required this.status,
    required this.days,
    required this.actionBy,
    required this.action,
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
  DateTime get fromDate => from;
  DateTime get toDate => to;
  DateTime get appliedDate => from; // Using from date as applied date
  int get totalDays => days;
  String get leaveType => type; // Alias for compatibility

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
        AppLogger.warning('Error parsing employee data: $e');
        employee = null;
      }
    }

    return Leave(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] is String 
          ? json['employeeId'] 
          : (json['employeeId'] is Map ? json['employeeId']['_id'] ?? json['employeeId']['id'] : ''),
      type: json['type'] ?? '',
      from: _parseDate(json['from']),
      to: _parseDate(json['to']),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'New',
      days: json['days'] ?? 0,
      actionBy: json['actionBy'] ?? 'HR',
      action: json['action'] ?? '-',
      employee: employee,
    );
  }

  // Helper method to parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    AppLogger.debug(
      'LeaveModel: Parsing date value: $dateValue (type: ${dateValue.runtimeType})',
    );
    try {
      // If it's already a DateTime object, return it
      if (dateValue is DateTime) {
        AppLogger.debug('LeaveModel: Date is already DateTime, returning as-is');
        return dateValue;
      }
      
      // If it's a String, try to parse it
      if (dateValue is String) {
        AppLogger.debug('LeaveModel: Date is String, attempting to parse');
        // Try parsing as ISO format first (for backward compatibility)
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          // If ISO parsing fails, try parsing "dd-MM-yyyy" format
          try {
            final parts = dateValue.split('-');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              return DateTime(year, month, day);
            }
          } catch (e) {
            AppLogger.warning(
              'Error parsing date string: $dateValue, using current date as fallback',
            );
            return DateTime.now();
          }
        }
      }
      
      // If it's neither DateTime nor String, return current date
      AppLogger.warning(
        'Unexpected date type: ${dateValue.runtimeType}, using current date as fallback',
      );
      return DateTime.now();
    } catch (e) {
      AppLogger.warning(
        'Error parsing date: $dateValue, using current date as fallback',
      );
      return DateTime.now();
    }
  }
}
