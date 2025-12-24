/// Custom exception thrown when API returns a 400 or 500 status code
/// Used to trigger mock data fallback in admin screens
class ServerErrorException implements Exception {
  final String message;
  final int statusCode;

  ServerErrorException(this.message, {this.statusCode = 400});

  @override
  String toString() => 'ServerErrorException: $message (Status: $statusCode)';
}
