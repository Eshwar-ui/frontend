import 'package:quantum_dashboard/utils/app_logger.dart';

class Holiday {
  final String id;
  final String title;
  final DateTime date;
  final String day;
  final String action;

  Holiday({
    required this.id,
    required this.title,
    required this.date,
    required this.day,
    required this.action,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      date: _parseDate(json['date']),
      day: json['day'] ?? '',
      action: json['action'] ?? '',
    );
  }

  // Helper method to parse date from various formats
  static DateTime _parseDate(dynamic dateValue) {
    AppLogger.debug(
      'HolidayModel: Parsing date value: $dateValue (type: ${dateValue.runtimeType})',
    );
    try {
      // If it's already a DateTime object, return it
      if (dateValue is DateTime) {
        AppLogger.debug('HolidayModel: Date is already DateTime, returning as-is');
        return dateValue;
      }
      
      // If it's a String, try to parse it
      if (dateValue is String) {
        AppLogger.debug('HolidayModel: Date is String, attempting to parse');
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

  // Helper method to get formatted date string
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Helper method to get year from date
  int get year => date.year;

  // Helper method to get month from date
  int get month => date.month;

  // Helper method to get day from date
  int get dayOfMonth => date.day;
}
