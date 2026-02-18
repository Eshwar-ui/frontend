import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_dashboard/utils/payslip_bulk_utils.dart';

void main() {
  group('PayslipBulkUtils.parseFileBytes', () {
    test('parses valid CSV row', () {
      const csv =
          'empId,month,year,basicSalary,HRA,TA,DA,conveyanceAllowance,total,employeesContributionPF,employersContributionPF,professionalTAX,totalDeductions,NetSalary,paidDays,LOPDays,arrear\r\n'
          'QWIT-1002,1,2026,35000,12000,2500,1800,1500,52800,4200,4200,200,8600,44200,30,0,0';
      final bytes = Uint8List.fromList(utf8.encode(csv));

      final result = PayslipBulkUtils.parseFileBytes(bytes, 'bulk.csv');

      expect(result.issues, isEmpty);
      expect(result.validRows, hasLength(1));
      expect(result.validRows.first['empId'], 'QWIT-1002');
      expect(result.validRows.first['month'], 1);
      expect(result.validRows.first['year'], 2026);
    });

    test('reports issues with row numbers for invalid CSV rows', () {
      const csv =
          'empId,month,year,basicSalary,paidDays,LOPDays\r\n'
          ',13,1999,0,-1,-2';
      final bytes = Uint8List.fromList(utf8.encode(csv));

      final result = PayslipBulkUtils.parseFileBytes(bytes, 'bulk.csv');

      expect(result.validRows, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.first.rowNumber, 2);
      expect(result.issues.first.message, contains('empId is required'));
      expect(result.issues.first.message, contains('month must be between 1 and 12'));
    });

    test('parses xlsx rows with header aliases', () {
      final excel = xls.Excel.createExcel();
      final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];
      final headers = [
        'Employee ID',
        'Month',
        'Year',
        'Basic Salary',
        'House Rent Allowance',
        'TA',
        'DA',
        'Conveyance Allowance',
        'Employee PF',
        'Employer PF',
        'PT',
        'Paid Days',
        'Loss of Pay Days',
        'Arrear',
      ];
      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = xls.TextCellValue(headers[i]);
      }
      final values = [
        'QWIT-1010',
        '1',
        '2026',
        '42000',
        '15000',
        '3000',
        '2200',
        '1800',
        '5040',
        '5040',
        '200',
        '29',
        '1',
        '500',
      ];
      for (var i = 0; i < values.length; i++) {
        sheet
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1))
            .value = xls.TextCellValue(values[i]);
      }

      final bytes = Uint8List.fromList(excel.encode()!);
      final result = PayslipBulkUtils.parseFileBytes(bytes, 'bulk.xlsx');

      expect(result.issues, isEmpty);
      expect(result.validRows, hasLength(1));
      expect(result.validRows.first['empId'], 'QWIT-1010');
      expect(result.validRows.first['hra'], 15000);
      expect(result.validRows.first['lopDays'], 1);
    });

    test('returns parse issues for unsupported extension and malformed xlsx', () {
      final unsupported = PayslipBulkUtils.parseFileBytes(
        Uint8List.fromList(utf8.encode('a,b\n1,2')),
        'bulk.txt',
      );
      final malformedXlsx = PayslipBulkUtils.parseFileBytes(
        Uint8List.fromList([1, 2, 3, 4]),
        'bad.xlsx',
      );

      expect(unsupported.validRows, isEmpty);
      expect(unsupported.issues, hasLength(1));
      expect(unsupported.issues.first.message, contains('Unsupported file format'));

      expect(malformedXlsx.validRows, isEmpty);
      expect(malformedXlsx.issues, hasLength(1));
      expect(malformedXlsx.issues.first.message, contains('Unable to parse Excel file'));
    });
  });
}
