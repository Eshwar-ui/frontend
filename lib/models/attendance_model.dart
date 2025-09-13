class Attendance {
  final String id;
  final String employeeId;
  final DateTime punchIn;
  final DateTime? punchOut;
  final double breakTime;
  final double totalWorkingTime;
  final DateTime? lastPunchedIn;
  final DateTime? lastPunchedOut;
  final String? lastPunchType;
  final String? employeeName;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.punchIn,
    this.punchOut,
    required this.breakTime,
    required this.totalWorkingTime,
    this.lastPunchedIn,
    this.lastPunchedOut,
    this.lastPunchType,
    this.employeeName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      punchIn: _parseDate(json['punchIn']),
      punchOut: json['punchOut'] != null ? _parseDate(json['punchOut']) : null,
      breakTime: (json['breakTime'] ?? 0).toDouble(),
      totalWorkingTime: (json['totalWorkingTime'] ?? 0).toDouble(),
      lastPunchedIn: json['lastPunchedIn'] != null ? _parseDate(json['lastPunchedIn']) : null,
      lastPunchedOut: json['lastPunchedOut'] != null ? _parseDate(json['lastPunchedOut']) : null,
      lastPunchType: json['lastPunchType'],
      employeeName: json['employeeName'],
    );
  }

  // Helper method to parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    print('AttendanceModel: Parsing date value: $dateValue (type: ${dateValue.runtimeType})');
    try {
      // If it's already a DateTime object, return it
      if (dateValue is DateTime) {
        print('AttendanceModel: Date is already DateTime, returning as-is');
        return dateValue;
      }
      
      // If it's a String, try to parse it
      if (dateValue is String) {
        print('AttendanceModel: Date is String, attempting to parse');
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
            print('Error parsing date string: $dateValue, using current date as fallback');
            return DateTime.now();
          }
        }
      }
      
      // If it's neither DateTime nor String, return current date
      print('Unexpected date type: ${dateValue.runtimeType}, using current date as fallback');
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $dateValue, using current date as fallback');
      return DateTime.now();
    }
  }

  // Helper method to get formatted working time
  String get formattedWorkingTime {
    final hours = (totalWorkingTime / 3600).floor();
    final minutes = ((totalWorkingTime % 3600) / 60).floor();
    return '${hours}:${minutes}HRS';
  }

  // Helper method to get formatted break time
  String get formattedBreakTime {
    final hours = (breakTime / 3600).floor();
    final minutes = ((breakTime % 3600) / 60).floor();
    return '${hours}:${minutes}HRS';
  }

  // Helper method to check if employee is currently punched in
  bool get isPunchedIn => punchOut == null;

  // Helper method to get attendance status based on working hours
  String get attendanceStatus {
    final workingHours = totalWorkingTime / 3600;
    if (workingHours >= 7.5) {
      return 'Present';
    } else if (workingHours >= 3.5) {
      return 'Half Day';
    } else {
      return 'Absent';
    }
  }
}
