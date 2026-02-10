import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class ExcelExportUtils {
  /// Export attendance data to Excel-compatible CSV file
  static Future<String?> exportAttendanceToExcel({
    required List<Map<String, dynamic>> attendanceData,
    required int month,
    required int year,
    required BuildContext context,
  }) async {
    try {
      // Request storage permission for Android (only for older versions)
      if (Platform.isAndroid) {
        // For Android 10 and below, request storage permission
        if (!await _isAndroid11OrAbove()) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Storage permission is required to save the file. Please grant permission in app settings.',
                  ),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () async {
                      await openAppSettings();
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            return null;
          }
        }
        // Android 11+ uses scoped storage - no special permission needed for app-specific directory
      }

      // Get days in month
      final daysInMonth = DateTime(year, month + 1, 0).day;

      // Build CSV data
      final List<List<dynamic>> csvData = [];

      // Headers
      final headers = ['Employee Name', 'Employee ID'];
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        headers.add(
          '${day.toString().padLeft(2, '0')} ${DateFormat('E').format(date).substring(0, 1)}',
        );
      }
      headers.addAll(['Total Present', 'Total Absent', 'Total Half Day']);
      csvData.add(headers);

      // Data rows
      for (final employeeData in attendanceData) {
        // Sanitize employee name - remove commas, quotes, and newlines that could break CSV
        final rawName = employeeData['employeeName']?.toString() ?? 'Unknown';
        final employeeName = rawName
            .replaceAll(',', ' ')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .trim();

        final employeeId =
            employeeData['employeeId']?.toString() ??
            employeeData['_id']?.toString() ??
            '';

        final row = [employeeName, employeeId];

        // Counters
        int presentCount = 0;
        int absentCount = 0;
        int halfDayCount = 0;

        // Daily attendance
        final List<dynamic> attendanceRecords =
            employeeData['attendance'] ?? [];
        for (int day = 1; day <= daysInMonth; day++) {
          final dateStr =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final record = attendanceRecords.firstWhere(
            (r) => r != null && r['date']?.toString() == dateStr,
            orElse: () => null,
          );

          if (record != null && record['attendanceStatus'] != null) {
            final status = record['attendanceStatus']?.toString() ?? '';
            // Use single character codes for better Excel compatibility
            String statusCode;
            if (status.toLowerCase().contains('present')) {
              statusCode = 'P';
              presentCount++;
            } else if (status.toLowerCase().contains('half')) {
              statusCode = 'H';
              halfDayCount++;
            } else if (status.toLowerCase().contains('absent')) {
              statusCode = 'A';
              absentCount++;
            } else {
              statusCode = status; // Keep original if unknown
            }
            row.add(statusCode);
          } else {
            row.add(
              '',
            ); // Empty cell instead of '-' for better Excel compatibility
          }
        }

        // Add totals
        row.addAll([
          presentCount.toString(),
          absentCount.toString(),
          halfDayCount.toString(),
        ]);
        csvData.add(row);
      }

      // Convert to CSV string with proper formatting
      // Use fieldDelimiter: ',' and textDelimiter: '"' for Excel compatibility
      final csvConverter = const ListToCsvConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        textEndDelimiter: '"',
        eol: '\r\n', // Windows line endings for better Excel compatibility
      );
      final csvString = csvConverter.convert(csvData);

      // Add UTF-8 BOM for Excel compatibility (Excel needs BOM to detect UTF-8)
      final utf8Bom = '\uFEFF';
      final csvWithBom = utf8Bom + csvString;

      // Get file path
      // For Android 11+, use app-specific external storage (no special permission needed)
      // For older Android versions, we use external storage with permission
      // For iOS, use documents directory
      Directory? directory;

      if (Platform.isAndroid) {
        // Use app-specific external storage directory
        // This works without MANAGE_EXTERNAL_STORAGE on Android 11+
        // And with standard storage permission on older versions
        directory = await getExternalStorageDirectory();
      } else {
        // iOS and other platforms
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to access storage directory'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      final monthName = DateFormat('MMMM').format(DateTime(year, month));
      final fileName = 'Attendance_${monthName}_$year.csv';
      final filePath = '${directory.path}/$fileName';

      // Save file with UTF-8 encoding and BOM
      final file = File(filePath);
      await file.writeAsString(
        csvWithBom,
        encoding: const Utf8Codec(allowMalformed: false),
        mode: FileMode.write,
        flush: true,
      );

      // Open file
      await OpenFilex.open(filePath);

      return filePath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting to Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Check if Android version is 11 or above (API 30+)
  static Future<bool> _isAndroid11OrAbove() async {
    if (!Platform.isAndroid) return false;
    try {
      // Try to check manageExternalStorage status
      // If this permission exists, it means Android 11+ (API 30+)
      await Permission.manageExternalStorage.status;
      return true;
    } catch (e) {
      // If permission doesn't exist or throws error, it's likely Android 10 or below
      return false;
    }
  }
}
