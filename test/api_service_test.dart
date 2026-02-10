import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/utils/server_error_exception.dart';

void main() {
  group('ApiService.handleResponse', () {
    test('returns empty map for empty 204 response', () {
      final api = ApiService();
      final response = http.Response('', 204);

      final result = api.handleResponse(response);

      expect(result, isA<Map<String, dynamic>>());
      expect(result, isEmpty);
    });

    test('throws ServerErrorException with server message', () {
      final api = ApiService();
      final response = http.Response(
        '{"error":"Unable to add employee. Please try again later."}',
        500,
      );

      expect(
        () => api.handleResponse(response),
        throwsA(
          isA<ServerErrorException>().having(
            (e) => e.message,
            'message',
            contains('Unable to add employee'),
          ),
        ),
      );
    });
  });
}
