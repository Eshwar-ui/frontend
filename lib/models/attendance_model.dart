import 'package:quantum_dashboard/utils/app_logger.dart';

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
    AppLogger.debug('AttendanceModel.fromJson: Full JSON data: $json');

    // Check for different possible break time field names
    double breakTimeValue = 0.0;
    final possibleBreakFields = [
      'totalBreakTime',
      'breakTime',
      'break_time',
      'breakDuration',
    ];

    for (String field in possibleBreakFields) {
      if (json[field] != null) {
        breakTimeValue = _parseBreakTime(json[field]);
        AppLogger.debug(
          'AttendanceModel.fromJson: Found break time in field "$field": ${json[field]} -> parsed as: $breakTimeValue seconds',
        );
        break;
      }
    }

    if (breakTimeValue == 0) {
      AppLogger.debug(
        'AttendanceModel.fromJson: No break time found in any field, checking all keys: ${json.keys.toList()}',
      );
    }

    return Attendance(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      punchIn: _parseDate(json['punchIn']),
      punchOut: json['punchOut'] != null ? _parseDate(json['punchOut']) : null,
      breakTime: breakTimeValue,
      totalWorkingTime: (json['totalWorkingTime'] ?? 0).toDouble(),
      lastPunchedIn: json['lastPunchedIn'] != null
          ? _parseDate(json['lastPunchedIn'])
          : null,
      lastPunchedOut: json['lastPunchedOut'] != null
          ? _parseDate(json['lastPunchedOut'])
          : null,
      lastPunchType: json['lastPunchType'],
      employeeName: json['employeeName'],
    );
  }

  // Helper method to parse break time from various formats (UTC time, duration, etc.)
  static double _parseBreakTime(dynamic breakValue) {
    AppLogger.debug(
      'AttendanceModel: Parsing break time value: $breakValue (type: ${breakValue.runtimeType})',
    );

    try {
      // If it's already a number, treat as seconds or milliseconds
      if (breakValue is num) {
        final numValue = breakValue.toDouble();
        AppLogger.debug('AttendanceModel: Break time is numeric: $numValue');
        return numValue;
      }

      // If it's a string, check if it's a time format
      if (breakValue is String) {
        // Try to parse as UTC time string first
        try {
          final dateTime = DateTime.parse(breakValue).toLocal();
          // If it's a valid datetime, calculate duration from midnight
          final midnight = DateTime(
            dateTime.year,
            dateTime.month,
            dateTime.day,
          );
          final durationFromMidnight = dateTime.difference(midnight);
          final seconds = durationFromMidnight.inSeconds.toDouble();
          AppLogger.debug(
            'AttendanceModel: Break time parsed as UTC time, duration from midnight: $seconds seconds',
          );
          return seconds;
        } catch (e) {
          AppLogger.debug(
            'AttendanceModel: Not a valid UTC time string, trying other formats',
          );
        }

        // Try to parse as HH:MM format
        try {
          final parts = breakValue.split(':');
          if (parts.length >= 2) {
            final hours = int.parse(parts[0]);
            final minutes = int.parse(parts[1]);
            final seconds = (hours * 3600) + (minutes * 60);
            AppLogger.debug(
              'AttendanceModel: Break time parsed as HH:MM format: $seconds seconds',
            );
            return seconds.toDouble();
          }
        } catch (e) {
          AppLogger.debug('AttendanceModel: Not a valid HH:MM format');
        }

        // Try to parse as pure number string
        try {
          final numValue = double.parse(breakValue);
          AppLogger.debug(
            'AttendanceModel: Break time parsed as number string: $numValue',
          );
          return numValue;
        } catch (e) {
          AppLogger.debug('AttendanceModel: Not a valid number string');
        }
      }

      AppLogger.debug('AttendanceModel: Could not parse break time, returning 0');
      return 0.0;
    } catch (e) {
      AppLogger.debug('AttendanceModel: Error parsing break time: $e, returning 0');
      return 0.0;
    }
  }

  // Helper method to parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    AppLogger.debug(
      'AttendanceModel: Parsing date value: $dateValue (type: ${dateValue.runtimeType})',
    );
    try {
      // If it's already a DateTime object, return it
      if (dateValue is DateTime) {
        AppLogger.debug('AttendanceModel: Date is already DateTime, returning as-is');
        return dateValue;
      }

      // If it's a String, try to parse it
      if (dateValue is String) {
        AppLogger.debug('AttendanceModel: Date is String, attempting to parse');
        // Try parsing as ISO format first (for backward compatibility)
        try {
          // Parse as UTC and convert to local time (IST)
          return DateTime.parse(dateValue).toLocal();
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
            AppLogger.debug(
              'Error parsing date string: $dateValue, using current date as fallback',
            );
            return DateTime.now();
          }
        }
      }

      // If it's neither DateTime nor String, return current date
      AppLogger.debug(
        'Unexpected date type: ${dateValue.runtimeType}, using current date as fallback',
      );
      return DateTime.now();
    } catch (e) {
      AppLogger.debug('Error parsing date: $dateValue, using current date as fallback');
      return DateTime.now();
    }
  }

  // Helper method to get formatted working time
  String get formattedWorkingTime {
    AppLogger.debug('AttendanceModel: Working time raw value: $totalWorkingTime');

    // Handle both seconds and milliseconds based on magnitude
    double timeInSeconds = totalWorkingTime > 86400
        ? totalWorkingTime /
              1000 // Convert milliseconds to seconds
        : totalWorkingTime; // Already in seconds

    AppLogger.debug('AttendanceModel: Working time in seconds: $timeInSeconds');

    final hours = (timeInSeconds / 3600).floor();
    final minutes = ((timeInSeconds % 3600) / 60).floor();
    final result = '$hours:${minutes.toString().padLeft(2, '0')} HRS';

    AppLogger.debug('AttendanceModel: Working time formatted: $result');
    return result;
  }

  // Helper method to get formatted break time
  String get formattedBreakTime {
    AppLogger.debug('AttendanceModel: Note - individual record shows partial break time');
    AppLogger.debug(
      'AttendanceModel: For total daily break time, use dashboard aggregation',
    );

    // For individual records, use the raw breakTime field or lastPunchedIn/Out
    double breakTimeInSeconds = _calculateBreakTimeFromRecord();

    if (breakTimeInSeconds <= 0) {
      return '0:00 HRS';
    }

    final hours = (breakTimeInSeconds / 3600).floor();
    final minutes = ((breakTimeInSeconds % 3600) / 60).floor();
    final result = hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')} HRS'
        : '$minutes MIN';

    AppLogger.debug(
      'AttendanceModel: Break time calculated: $breakTimeInSeconds seconds -> $result',
    );
    return result;
  }

  // Helper method to calculate break time from this record
  double _calculateBreakTimeFromRecord() {
    try {
      // Use the raw breakTime field if available
      if (breakTime > 0) {
        AppLogger.debug('AttendanceModel: Using raw breakTime field: $breakTime');
        // Convert breakTime to seconds if it's in a different unit
        if (breakTime > 86400) {
          // Likely milliseconds
          return breakTime / 1000;
        } else {
          // Already in seconds or minutes, detect based on magnitude
          return breakTime <= 480
              ? breakTime * 60
              : breakTime; // Convert minutes to seconds if <= 8 hours
        }
      }

      // Fallback: try lastPunchedIn/Out if they represent a break session
      if (lastPunchedIn != null && lastPunchedOut != null) {
        AppLogger.debug(
          'AttendanceModel: Using lastPunchedIn/Out: $lastPunchedIn to $lastPunchedOut',
        );
        final breakDuration = lastPunchedOut!.difference(lastPunchedIn!);
        return breakDuration.inSeconds.toDouble();
      }

      AppLogger.debug('AttendanceModel: No break time data available');
      return 0.0;
    } catch (e) {
      AppLogger.debug('AttendanceModel: Error calculating break time: $e');
      return 0.0;
    }
  }

  // Helper method to check if employee is currently punched in
  bool get isPunchedIn => punchOut == null;

  // Helper method to get attendance status based on working hours
  String get attendanceStatus {
    // Handle both seconds and milliseconds based on magnitude
    double timeInSeconds = totalWorkingTime > 86400
        ? totalWorkingTime /
              1000 // Convert milliseconds to seconds
        : totalWorkingTime; // Already in seconds

    final workingHours = timeInSeconds / 3600;
    if (workingHours >= 7.5) {
      return 'Present';
    } else if (workingHours >= 3.5) {
      return 'Half Day';
    } else {
      return 'Absent';
    }
  }
}

