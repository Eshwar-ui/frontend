import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/services/payslip_service.dart';
import 'package:quantum_dashboard/utils/payslip_bulk_utils.dart';

class FakePayslipService extends PayslipService {
  Map<String, dynamic> nextBulkResponse = const {};
  Object? bulkError;
  List<Map<String, dynamic>>? lastBulkRows;

  @override
  Future<Map<String, dynamic>> bulkGeneratePayslips(
    List<Map<String, dynamic>> rows,
  ) async {
    lastBulkRows = rows;
    if (bulkError != null) {
      throw bulkError!;
    }
    return nextBulkResponse;
  }
}

void main() {
  group('PayslipProvider.bulkGeneratePayslips', () {
    test('sends parsed rows and returns summary payload', () async {
      const csv =
          'empId,month,year,basicSalary,HRA,TA,DA,conveyanceAllowance,total,employeesContributionPF,employersContributionPF,professionalTAX,totalDeductions,NetSalary,paidDays,LOPDays,arrear\r\n'
          'QWIT-1002,1,2026,35000,12000,2500,1800,1500,52800,4200,4200,200,8600,44200,30,0,0\r\n'
          'QWIT-9999,1,2026,0,0,0,0,0,0,0,0,0,0,0,30,0,0';
      final parsed = PayslipBulkUtils.parseFileBytes(
        Uint8List.fromList(utf8.encode(csv)),
        'bulk.csv',
      );
      expect(parsed.validRows, hasLength(1));
      expect(parsed.issues, hasLength(1));

      final fakeService = FakePayslipService()
        ..nextBulkResponse = {
          'totalRows': 1,
          'successCount': 1,
          'failureCount': 0,
          'results': [
            {
              'rowNumber': 1,
              'empId': 'QWIT-1002',
              'status': 'success',
              'message': 'Payslip generated and saved successfully',
            },
          ],
        };

      final provider = PayslipProvider(payslipService: fakeService);
      var sawLoading = false;
      provider.addListener(() {
        if (provider.isLoading) {
          sawLoading = true;
        }
      });

      final result = await provider.bulkGeneratePayslips(parsed.validRows);

      expect(sawLoading, isTrue);
      expect(fakeService.lastBulkRows, equals(parsed.validRows));
      expect(result['totalRows'], 1);
      expect(result['successCount'], 1);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('captures service exception and exposes error state', () async {
      final fakeService = FakePayslipService()
        ..bulkError = Exception('bulk API failed');
      final provider = PayslipProvider(payslipService: fakeService);

      final result = await provider.bulkGeneratePayslips([
        {'empId': 'QWIT-1002', 'month': 1, 'year': 2026, 'basicSalary': 35000},
      ]);

      expect(result['success'], isFalse);
      expect(result['error'].toString(), contains('bulk API failed'));
      expect(provider.error, contains('bulk API failed'));
      expect(provider.isLoading, isFalse);
    });
  });
}
