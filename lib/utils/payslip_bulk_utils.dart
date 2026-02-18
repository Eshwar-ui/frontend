import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class BulkPayslipParseIssue {
  final int rowNumber;
  final String message;

  BulkPayslipParseIssue({required this.rowNumber, required this.message});
}

class BulkPayslipParseResult {
  final List<Map<String, dynamic>> validRows;
  final List<BulkPayslipParseIssue> issues;

  BulkPayslipParseResult({required this.validRows, required this.issues});
}

class PayslipBulkUtils {
  static const List<String> templateHeaders = [
    'empId',
    'month',
    'year',
    'basicSalary',
    'HRA',
    'TA',
    'DA',
    'conveyanceAllowance',
    'total',
    'employeesContributionPF',
    'employersContributionPF',
    'professionalTAX',
    'totalDeductions',
    'NetSalary',
    'paidDays',
    'LOPDays',
    'arrear',
  ];

  static const List<List<String>> sampleRows = [
    [
      'QWIT-1002',
      '1',
      '2026',
      '35000',
      '12000',
      '2500',
      '1800',
      '1500',
      '52800',
      '4200',
      '4200',
      '200',
      '8600',
      '44200',
      '30',
      '0',
      '0',
    ],
    [
      'QWIT-1010',
      '1',
      '2026',
      '42000',
      '15000',
      '3000',
      '2200',
      '1800',
      '64000',
      '5040',
      '5040',
      '200',
      '10280',
      '53720',
      '29',
      '1',
      '500',
    ],
  ];

  static Future<String> exportTemplateXlsx() async {
    Directory directory;
    if (Platform.isAndroid) {
      directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final templateDir = Directory('${directory.path}/bulk_payslip_templates');
    if (!templateDir.existsSync()) {
      templateDir.createSync(recursive: true);
    }

    final excel = xls.Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    for (int col = 0; col < templateHeaders.length; col++) {
      sheet
          .cell(xls.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = xls.TextCellValue(
        templateHeaders[col],
      );
    }

    for (int row = 0; row < sampleRows.length; row++) {
      final values = sampleRows[row];
      for (int col = 0; col < values.length; col++) {
        sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: row + 1,
              ),
            )
            .value = xls.TextCellValue(
          values[col],
        );
      }
    }

    final bytes = excel.encode();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to generate template file');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath =
        '${templateDir.path}/payslip_bulk_template_$timestamp.xlsx';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    try {
      await OpenFilex.open(filePath);
    } catch (_) {
      // Non-blocking: returning the saved path is enough for manual access.
    }
    return filePath;
  }

  static BulkPayslipParseResult parseFileBytes(
    Uint8List bytes,
    String fileName,
  ) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.xlsx')) {
      return _parseXlsxBytes(bytes);
    }
    if (lower.endsWith('.csv')) {
      return _parseCsvBytes(bytes);
    }
    return BulkPayslipParseResult(
      validRows: [],
      issues: [
        BulkPayslipParseIssue(
          rowNumber: 1,
          message: 'Unsupported file format. Use .xlsx or .csv',
        ),
      ],
    );
  }

  static BulkPayslipParseResult _parseCsvBytes(Uint8List bytes) {
    List<List<dynamic>> rows;
    try {
      final content = utf8.decode(bytes, allowMalformed: true);
      rows = const CsvToListConverter(
        shouldParseNumbers: false,
      ).convert(content);
    } catch (_) {
      return BulkPayslipParseResult(
        validRows: [],
        issues: [
          BulkPayslipParseIssue(
            rowNumber: 1,
            message: 'Unable to parse CSV file',
          ),
        ],
      );
    }

    final normalizedRows = rows
        .map((r) => r.map((e) => (e ?? '').toString()).toList(growable: false))
        .toList(growable: false);

    return _parseRows(normalizedRows);
  }

  static BulkPayslipParseResult _parseXlsxBytes(Uint8List bytes) {
    xls.Excel excel;
    try {
      excel = xls.Excel.decodeBytes(bytes);
    } catch (_) {
      return BulkPayslipParseResult(
        validRows: [],
        issues: [
          BulkPayslipParseIssue(
            rowNumber: 1,
            message: 'Unable to parse Excel file',
          ),
        ],
      );
    }
    if (excel.tables.isEmpty) {
      return BulkPayslipParseResult(
        validRows: [],
        issues: [
          BulkPayslipParseIssue(rowNumber: 1, message: 'Excel file is empty'),
        ],
      );
    }

    final firstTable = excel.tables.values.first;
    if (firstTable.rows.isEmpty) {
      return BulkPayslipParseResult(
        validRows: [],
        issues: [
          BulkPayslipParseIssue(
            rowNumber: 1,
            message: 'Excel file has no rows',
          ),
        ],
      );
    }

    final normalizedRows = firstTable.rows
        .map(
          (row) => row
              .map((cell) => cell?.value?.toString() ?? '')
              .toList(growable: false),
        )
        .toList(growable: false);

    return _parseRows(normalizedRows);
  }

  static BulkPayslipParseResult _parseRows(List<List<String>> rows) {
    if (rows.isEmpty) {
      return BulkPayslipParseResult(
        validRows: [],
        issues: [BulkPayslipParseIssue(rowNumber: 1, message: 'File is empty')],
      );
    }

    final headers = rows.first.map((e) => e.trim()).toList();
    final keyToIndex = _buildHeaderIndex(headers);

    final issues = <BulkPayslipParseIssue>[];
    final validRows = <Map<String, dynamic>>[];

    for (int i = 1; i < rows.length; i++) {
      final rowNumber = i + 1;
      final row = rows[i];

      if (_isRowEmpty(row)) continue;

      final normalized = <String, dynamic>{};
      final rowIssues = <String>[];

      String readText(String key) {
        final idx = keyToIndex[key];
        if (idx == null || idx >= row.length) return '';
        return row[idx].trim();
      }

      int? readInt(String key, {required bool required}) {
        final raw = readText(key);
        if (raw.isEmpty) {
          if (required) {
            rowIssues.add('$key is required');
          }
          return null;
        }
        final value = int.tryParse(raw);
        if (value == null) {
          rowIssues.add('$key must be an integer');
          return null;
        }
        return value;
      }

      double readDouble(String key, {double fallback = 0}) {
        final raw = readText(key);
        if (raw.isEmpty) return fallback;
        final value = double.tryParse(raw);
        if (value == null) {
          rowIssues.add('$key must be a valid number');
          return fallback;
        }
        return value;
      }

      final empId = readText('empId');
      if (empId.isEmpty) {
        rowIssues.add('empId is required');
      }
      normalized['empId'] = empId;

      final month = readInt('month', required: true) ?? 0;
      final year = readInt('year', required: true) ?? 0;
      final paidDays = readInt('paidDays', required: true) ?? 0;
      final lopDays = readInt('lopDays', required: false) ?? 0;

      if (month < 1 || month > 12) {
        rowIssues.add('month must be between 1 and 12');
      }
      if (year < 2000 || year > 2100) {
        rowIssues.add('year must be between 2000 and 2100');
      }
      if (paidDays < 0) {
        rowIssues.add('paidDays cannot be negative');
      }
      if (lopDays < 0) {
        rowIssues.add('lopDays cannot be negative');
      }

      normalized['month'] = month;
      normalized['year'] = year;
      normalized['paidDays'] = paidDays;
      normalized['lopDays'] = lopDays;

      final basicSalary = readDouble('basicSalary');
      final hra = readDouble('hra');
      final ta = readDouble('ta');
      final da = readDouble('da');
      final conveyanceAllowance = readDouble('conveyanceAllowance');
      final employeesContributionPF = readDouble('employeesContributionPF');
      final employersContributionPF = readDouble('employersContributionPF');
      final professionalTAX = readDouble('professionalTAX');
      final arrear = readDouble('arrear');

      if (basicSalary <= 0) {
        rowIssues.add('basicSalary must be greater than 0');
      }

      final totalFromInput = readText('total');
      final totalDeductionsFromInput = readText('totalDeductions');
      final netSalaryFromInput = readText('netSalary');

      final total = totalFromInput.isNotEmpty
          ? readDouble('total')
          : basicSalary + hra + ta + da + conveyanceAllowance;
      final totalDeductions = totalDeductionsFromInput.isNotEmpty
          ? readDouble('totalDeductions')
          : employeesContributionPF + employersContributionPF + professionalTAX;
      final netSalary = netSalaryFromInput.isNotEmpty
          ? readDouble('netSalary')
          : total - totalDeductions;

      normalized['basicSalary'] = basicSalary;
      normalized['hra'] = hra;
      normalized['ta'] = ta;
      normalized['da'] = da;
      normalized['conveyanceAllowance'] = conveyanceAllowance;
      normalized['employeesContributionPF'] = employeesContributionPF;
      normalized['employersContributionPF'] = employersContributionPF;
      normalized['professionalTAX'] = professionalTAX;
      normalized['total'] = total;
      normalized['totalDeductions'] = totalDeductions;
      normalized['netSalary'] = netSalary;
      normalized['arrear'] = arrear;

      if (rowIssues.isEmpty) {
        validRows.add(normalized);
      } else {
        issues.add(
          BulkPayslipParseIssue(
            rowNumber: rowNumber,
            message: rowIssues.join(', '),
          ),
        );
      }
    }

    return BulkPayslipParseResult(validRows: validRows, issues: issues);
  }

  static Map<String, int> _buildHeaderIndex(List<String> headers) {
    final map = <String, int>{};

    String normalize(String value) {
      final lower = value.toLowerCase();
      return lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    final aliases = <String, List<String>>{
      'empId': ['empid', 'employeeid'],
      'month': ['month'],
      'year': ['year'],
      'basicSalary': ['basicsalary'],
      'hra': ['hra', 'houserentallowance'],
      'ta': ['ta', 'travelallowance'],
      'da': ['da', 'dearnessallowance'],
      'conveyanceAllowance': ['conveyanceallowance'],
      'total': ['total', 'totalearnings'],
      'employeesContributionPF': ['employeescontributionpf', 'employeepf'],
      'employersContributionPF': ['employerscontributionpf', 'employerpf'],
      'professionalTAX': ['professionaltax', 'pt'],
      'totalDeductions': ['totaldeductions'],
      'netSalary': ['netsalary', 'netpay'],
      'paidDays': ['paiddays'],
      'lopDays': ['lopdays', 'lossofpaydays'],
      'arrear': ['arrear'],
    };

    for (int i = 0; i < headers.length; i++) {
      final normalizedHeader = normalize(headers[i]);
      for (final entry in aliases.entries) {
        if (entry.value.contains(normalizedHeader)) {
          map[entry.key] = i;
        }
      }
    }

    return map;
  }

  static bool _isRowEmpty(List<String> row) {
    for (final value in row) {
      if (value.trim().isNotEmpty) {
        return false;
      }
    }
    return true;
  }
}
