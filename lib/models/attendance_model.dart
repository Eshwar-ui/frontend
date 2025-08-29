class CheckIn {
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;

  CheckIn({
    required this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'])
          : null,
      status: json['status'],
    );
  }
}

class Attendance {
  final String id;
  final String employeeId;
  final DateTime date;
  final List<CheckIn> checkIns;
  final double totalWorkingTime;
  final double totalBreakTime;
  final String status;
  final String? remarks;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.checkIns,
    required this.totalWorkingTime,
    required this.totalBreakTime,
    required this.status,
    this.remarks,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'],
      employeeId: json['employeeId'],
      date: DateTime.parse(json['date']),
      checkIns: (json['checkIns'] as List)
          .map((checkInJson) => CheckIn.fromJson(checkInJson))
          .toList(),
      totalWorkingTime: json['totalWorkingTime']?.toDouble() ?? 0.0,
      totalBreakTime: json['totalBreakTime']?.toDouble() ?? 0.0,
      status: json['status'],
      remarks: json['remarks'],
    );
  }
}
