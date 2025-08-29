class Holiday {
  final String id;
  final int sNo;
  final String holidayName;
  final String date;
  final String day;
  final String postBy;

  Holiday({
    required this.id,
    required this.sNo,
    required this.holidayName,
    required this.date,
    required this.day,
    required this.postBy,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['_id'],
      sNo: json['S.No'] ?? 0,
      holidayName: json['Holiday Name'] ?? '',
      date: json['Date'] ?? '',
      day: json['Day'] ?? '',
      postBy: json['Post By'] ?? '',
    );
  }

  // Helper method to parse date string to DateTime if needed
  DateTime? get parsedDate {
    try {
      // Parse date in format "15-08-2025"
      final parts = date.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  // Helper method to get year from date string
  int? get year {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return int.parse(parts[2]);
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }
}