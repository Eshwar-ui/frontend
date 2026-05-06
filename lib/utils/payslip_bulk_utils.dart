import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quantum_dashboard/utils/download_saver.dart';

class TemplateExportResult {
  final String filePath;
  final bool opened;
  final String? openMessage;
  final SavedDownload? download;

  const TemplateExportResult({
    required this.filePath,
    required this.opened,
    this.openMessage,
    this.download,
  });
}

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
  // These are the headers we export in the template file. The parser is flexible
  // and will accept common variants/spellings via `_buildHeaderIndex`.
  //
  // Note: Month/Year are required by the backend generation endpoint.
  static const List<String> templateHeaders = [
    'Emp Id',
    'Name',
    'PF Number',
    'UAN Number',
    'ESI Number',
    'Month',
    'Year',
    'Basic Salary',
    'HRA',
    'TA',
    'DA',
    'CA',
    'Arrear',
    'Total',
    'Paid Days',
    'LOP Days',
    'PF',
    'Professional TAX',
    'ESI',
    'Total Deductions',
    'NET Salary',
  ];

  static const List<List<String>> sampleRows = [
    [
      'QWIT-1002',
      'Employee Name',
      'PF-000000',
      'UAN-000000',
      'ESI-000000',
      '1',
      '2026',
      '35000',
      '12000',
      '2500',
      '1800',
      '1500',
      '0',
      '52800',
      '30',
      '0',
      '4200',
      '200',
      '0',
      '4400',
      '48400',
    ],
    [
      'QWIT-1010',
      'Employee Name',
      'PF-000000',
      'UAN-000000',
      'ESI-000000',
      '1',
      '2026',
      '42000',
      '15000',
      '3000',
      '2200',
      '1800',
      '500',
      '64500',
      '29',
      '1',
      '5040',
      '200',
      '0',
      '5240',
      '59260',
    ],
  ];

  static Future<TemplateExportResult> exportTemplateXlsx({
    Directory? baseDirectory,
    Future<OpenResult> Function(String filePath)? openFile,
  }) async {
    final bytes = _buildTemplateXlsxBytes();
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Failed to generate template file');
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'payslip_bulk_template_$timestamp.xlsx';

    if (baseDirectory == null && openFile == null) {
      final download = await DownloadSaver.saveBytesToDownloads(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      return TemplateExportResult(
        filePath: download.displayPath,
        opened: false,
        download: download,
      );
    }

    final directory = baseDirectory ?? await _resolveExportBaseDirectory();
    final templateDir = Directory('${directory.path}/bulk_payslip_templates');
    if (!templateDir.existsSync()) {
      templateDir.createSync(recursive: true);
    }

    final filePath = '${templateDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    final openFileCallback = openFile ?? OpenFilex.open;
    try {
      final openResult = await openFileCallback(filePath);
      if (openResult.type == ResultType.done) {
        return TemplateExportResult(filePath: filePath, opened: true);
      }

      return TemplateExportResult(
        filePath: filePath,
        opened: false,
        openMessage: openResult.message.trim().isEmpty
            ? null
            : openResult.message,
      );
    } catch (e) {
      return TemplateExportResult(
        filePath: filePath,
        opened: false,
        openMessage: e.toString(),
      );
    }
  }

  static Future<Directory> _resolveExportBaseDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  static List<int>? _buildTemplateXlsxBytes() {
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

    return excel.encode();
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

      // Optional metadata fields (kept for traceability; backend uses employee
      // master data for these today, but we accept them in the sheet).
      final name = readText('name');
      if (name.isNotEmpty) normalized['name'] = name;
      final pfNo = readText('pfNo');
      if (pfNo.isNotEmpty) normalized['pfNo'] = pfNo;
      final uan = readText('uan');
      if (uan.isNotEmpty) normalized['uan'] = uan;
      final esiNo = readText('esiNo');
      if (esiNo.isNotEmpty) normalized['esiNo'] = esiNo;

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
      final esi = readDouble('esi');
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
          : employeesContributionPF +
                employersContributionPF +
                professionalTAX +
                esi;
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
      normalized['esi'] = esi;
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
      'name': ['name', 'employeename', 'employee'],
      'pfNo': ['pfno', 'pfnumber', 'pfn'],
      'uan': ['uan', 'uannumber'],
      'esiNo': ['esino', 'esinumber'],
      'month': ['month'],
      'year': ['year'],
      'basicSalary': ['basicsalary'],
      'hra': ['hra', 'houserentallowance'],
      'ta': ['ta', 'travelallowance'],
      'da': ['da', 'dearnessallowance'],
      'conveyanceAllowance': ['conveyanceallowance', 'ca'],
      'total': ['total', 'totalearnings'],
      // Common bulk sheets tend to have a single PF column. We treat it as the
      // employee PF deduction (the PDF template currently uses only employee PF).
      'employeesContributionPF': [
        'employeescontributionpf',
        'employeepf',
        'pf',
      ],
      'employersContributionPF': ['employerscontributionpf', 'employerpf'],
      'professionalTAX': ['professionaltax', 'pt', 'professionaltaxamount'],
      // ESI deduction amount is accepted in the sheet; backend currently ignores it.
      'esi': ['esi', 'esiamount', 'esideduction'],
      'totalDeductions': ['totaldeductions'],
      'netSalary': ['netsalary', 'netpay', 'netsalaryamount'],
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
