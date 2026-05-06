import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/utils/download_saver.dart';

class ExcelExportUtils {
  static final xls.CellStyle _headerStyle = xls.CellStyle(
    bold: true,
    fontColorHex: xls.ExcelColor.white,
    backgroundColorHex: xls.ExcelColor.blueGrey,
    horizontalAlign: xls.HorizontalAlign.Center,
    verticalAlign: xls.VerticalAlign.Center,
  );

  static final xls.CellStyle _defaultCellStyle = xls.CellStyle(
    horizontalAlign: xls.HorizontalAlign.Center,
    verticalAlign: xls.VerticalAlign.Center,
  );

  static final xls.CellStyle _lateCellStyle = xls.CellStyle(
    horizontalAlign: xls.HorizontalAlign.Center,
    verticalAlign: xls.VerticalAlign.Center,
    bold: true,
    backgroundColorHex: xls.ExcelColor.redAccent100,
    fontColorHex: xls.ExcelColor.redAccent700,
  );

  static final xls.CellStyle _totalsStyle = xls.CellStyle(
    horizontalAlign: xls.HorizontalAlign.Center,
    verticalAlign: xls.VerticalAlign.Center,
    bold: true,
    backgroundColorHex: xls.ExcelColor.fromHexString('FFD9EAF7'),
  );

  static Future<String?> exportEmployeesToExcel({
    required List<Employee> employees,
    required BuildContext context,
  }) async {
    try {
      if (employees.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No employee data to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      if (!await _ensureStoragePermission(context)) {
        return null;
      }

      final excel = xls.Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Employees';
      final sheet = excel[sheetName];

      const headers = <String>[
        'Employee ID',
        'First Name',
        'Last Name',
        'Full Name',
        'Email',
        'Mobile',
        'Date of Birth',
        'Joining Date',
        'Department',
        'Designation',
        'Gender',
        'Grade',
        'Role',
        'Reporting Manager',
        'Father Name',
        'Address',
        'Bank Name',
        'Account Number',
        'IFSC Code',
        'PAN Number',
        'PF Number',
        'UAN Number',
        'ESI Number',
        'Status',
        'Mobile Access Enabled',
        'Shift Start Time',
        'Shift End Time',
        'Profile Image',
      ];

      for (int col = 0; col < headers.length; col++) {
        final headerCell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        headerCell.value = xls.TextCellValue(headers[col]);
        headerCell.cellStyle = _headerStyle;
      }

      final sortedEmployees = [...employees]
        ..sort((a, b) => a.employeeId.compareTo(b.employeeId));

      for (int rowIndex = 0; rowIndex < sortedEmployees.length; rowIndex++) {
        final employee = sortedEmployees[rowIndex];
        final values = <String>[
          employee.employeeId,
          employee.firstName,
          employee.lastName,
          employee.fullName,
          employee.email,
          employee.mobile,
          _formatDate(employee.dateOfBirth),
          _formatDate(employee.joiningDate),
          _clean(employee.department),
          _clean(employee.designation),
          _clean(employee.gender),
          _clean(employee.grade),
          _clean(employee.role),
          _clean(employee.report),
          _clean(employee.fathername),
          _clean(employee.address),
          _clean(employee.bankname),
          _clean(employee.accountnumber),
          _clean(employee.ifsccode),
          _clean(employee.PANno),
          _clean(employee.PFno),
          _clean(employee.UANno),
          _clean(employee.ESIno),
          employee.status,
          employee.mobileAccessEnabled == true ? 'Yes' : 'No',
          _clean(employee.shiftStartTime),
          _clean(employee.shiftEndTime),
          employee.profileImage,
        ];

        for (int col = 0; col < values.length; col++) {
          final cell = sheet.cell(
            xls.CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex + 1,
            ),
          );
          cell.value = xls.TextCellValue(values[col]);
          cell.cellStyle = _defaultCellStyle;
        }
      }

      sheet.setColumnWidth(0, 18);
      sheet.setColumnWidth(1, 18);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 28);
      sheet.setColumnWidth(4, 32);
      sheet.setColumnWidth(5, 18);
      sheet.setColumnWidth(6, 16);
      sheet.setColumnWidth(7, 16);
      sheet.setColumnWidth(8, 24);
      sheet.setColumnWidth(9, 24);
      sheet.setColumnWidth(13, 24);
      sheet.setColumnWidth(15, 36);
      sheet.setColumnWidth(27, 36);

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'Employees_$timestamp.xlsx';
      final fileBytes = excel.encode();
      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('Unable to generate XLSX file');
      }

      final download = await DownloadSaver.saveBytesToDownloads(
        bytes: Uint8List.fromList(fileBytes),
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (context.mounted) {
        DownloadSaver.showSavedSnackBar(
          context: context,
          download: download,
          message: 'Employee details exported successfully',
        );
      }

      return download.displayPath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting employees: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Export attendance data to styled XLSX file
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

      // Build header row
      final headers = <String>['Employee Name', 'Employee ID'];
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        headers.add(
          '${day.toString().padLeft(2, '0')} ${DateFormat('E').format(date).substring(0, 1)}',
        );
      }
      headers.addAll([
        'Total Present',
        'Total Absent',
        'Total Half Day',
        'Total Leave',
        'Total Compoff',
      ]);

      final excel = xls.Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? 'Attendance';
      final sheet = excel[sheetName];

      // Header styles
      for (int col = 0; col < headers.length; col++) {
        final headerCell = sheet.cell(
          xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        headerCell.value = xls.TextCellValue(headers[col]);
        headerCell.cellStyle = _headerStyle;
      }

      // Data rows
      for (int rowIndex = 0; rowIndex < attendanceData.length; rowIndex++) {
        final employeeData = attendanceData[rowIndex];
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

        // Counters
        int presentCount = 0;
        int absentCount = 0;
        int halfDayCount = 0;
        int leaveCount = 0;
        int compoffCount = 0;

        // Daily attendance
        final List<dynamic> attendanceRecords =
            employeeData['attendance'] ?? [];
        final rowValues = <String>[employeeName, employeeId];
        final lateFlags = <bool>[false, false];

        for (int day = 1; day <= daysInMonth; day++) {
          final dateStr =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final record = attendanceRecords.firstWhere(
            (r) => r != null && r['date']?.toString() == dateStr,
            orElse: () => null,
          );

          if (record != null && record['attendanceStatus'] != null) {
            final status = record['attendanceStatus']?.toString() ?? '';
            final lateCode = (record['lateCode'] ?? '').toString().trim();
            final isLatePunchIn = record['isLatePunchIn'] == true;
            final isLatePunchOut = record['isLatePunchOut'] == true;
            String resolvedLateCode = lateCode;
            if (resolvedLateCode.isEmpty) {
              if (isLatePunchIn && isLatePunchOut) {
                resolvedLateCode = 'LI+LO';
              } else if (isLatePunchIn) {
                resolvedLateCode = 'LI';
              } else if (isLatePunchOut) {
                resolvedLateCode = 'LO';
              }
            }

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
            } else if (status.toLowerCase().contains('compoff')) {
              statusCode = 'C';
              compoffCount++;
            } else if (status.toLowerCase().contains('leave')) {
              statusCode = 'L';
              leaveCount++;
            } else {
              statusCode = status; // Keep original if unknown
            }
            if (resolvedLateCode.isNotEmpty &&
                (statusCode == 'P' || statusCode == 'H')) {
              statusCode = '$statusCode($resolvedLateCode)';
              lateFlags.add(true);
            } else {
              lateFlags.add(false);
            }
            rowValues.add(statusCode);
          } else {
            rowValues.add(
              '',
            ); // Empty cell instead of '-' for better Excel compatibility
            lateFlags.add(false);
          }
        }

        // Add totals
        rowValues.addAll([
          presentCount.toString(),
          absentCount.toString(),
          halfDayCount.toString(),
          leaveCount.toString(),
          compoffCount.toString(),
        ]);

        // Write row values and styles
        for (int col = 0; col < rowValues.length; col++) {
          final cell = sheet.cell(
            xls.CellIndex.indexByColumnRow(
              columnIndex: col,
              rowIndex: rowIndex + 1,
            ),
          );
          cell.value = xls.TextCellValue(rowValues[col]);

          if (col >= (2 + daysInMonth)) {
            cell.cellStyle = _totalsStyle;
          } else if (col >= 2 && col < 2 + daysInMonth && lateFlags[col]) {
            cell.cellStyle = _lateCellStyle;
          } else {
            cell.cellStyle = _defaultCellStyle;
          }
        }
      }

      // Set helpful column widths
      sheet.setColumnWidth(0, 30);
      sheet.setColumnWidth(1, 18);
      for (int dayCol = 2; dayCol < 2 + daysInMonth; dayCol++) {
        sheet.setColumnWidth(dayCol, 10);
      }
      for (
        int totalCol = 2 + daysInMonth;
        totalCol < headers.length;
        totalCol++
      ) {
        sheet.setColumnWidth(totalCol, 12);
      }

      final monthName = DateFormat('MMMM').format(DateTime(year, month));
      final fileName = 'Attendance_${monthName}_$year.xlsx';

      // Save file bytes
      final List<int>? fileBytes = excel.encode();
      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception('Unable to generate XLSX file');
      }

      final download = await DownloadSaver.saveBytesToDownloads(
        bytes: Uint8List.fromList(fileBytes),
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (context.mounted) {
        DownloadSaver.showSavedSnackBar(
          context: context,
          download: download,
          message: 'Attendance sheet exported successfully',
        );
      }

      return download.displayPath;
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
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 30;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _ensureStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid || await _isAndroid11OrAbove()) {
      return true;
    }

    final status = await Permission.storage.request();
    if (status.isGranted) {
      return true;
    }

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

    return false;
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  static String _clean(String? value) {
    return value?.replaceAll('\n', ' ').replaceAll('\r', ' ').trim() ?? '';
  }
}
