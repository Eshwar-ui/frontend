import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/company_location_model.dart';
import 'package:quantum_dashboard/models/employee_location_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class LocationService extends ApiService {
  // ==================== Company Location Methods ====================

  // Get all company locations
  Future<List<CompanyLocation>> getCompanyLocations() async {
    final url = '${ApiService.baseUrl}/api/company-locations';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    final data = handleResponse(response);

    if (data is List) {
      return data.map((json) => CompanyLocation.fromJson(json)).toList();
    }
    return [];
  }

  // Create company location
  Future<Map<String, dynamic>> createCompanyLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final url = '${ApiService.baseUrl}/api/company-locations';
    final headers = await getHeaders();

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return handleResponse(response);
  }

  // Update company location
  Future<Map<String, dynamic>> updateCompanyLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final url = '${ApiService.baseUrl}/api/company-locations/$id';
    final headers = await getHeaders();

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );
    return handleResponse(response);
  }

  // Delete company location
  Future<Map<String, dynamic>> deleteCompanyLocation(String id) async {
    final url = '${ApiService.baseUrl}/api/company-locations/$id';
    final headers = await getHeaders();

    final response = await http.delete(Uri.parse(url), headers: headers);
    return handleResponse(response);
  }

  // ==================== Employee Location Methods ====================

  // Get locations for a specific employee
  Future<List<EmployeeLocation>> getEmployeeLocations(String employeeId) async {
    final url = '${ApiService.baseUrl}/api/employee-locations/$employeeId';
    final headers = await getHeaders();

    final response = await http.get(Uri.parse(url), headers: headers);
    final data = handleResponse(response);

    if (data is List) {
      return data.map((json) => EmployeeLocation.fromJson(json)).toList();
    }
    return [];
  }

  // Create employee location
  Future<Map<String, dynamic>> createEmployeeLocation({
    required String employeeId,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final url = '${ApiService.baseUrl}/api/employee-locations';
    final headers = await getHeaders();

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'employeeId': employeeId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    return handleResponse(response);
  }

  // Update employee location
  Future<Map<String, dynamic>> updateEmployeeLocation({
    required String id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final url = '${ApiService.baseUrl}/api/employee-locations/$id';
    final headers = await getHeaders();

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );
    return handleResponse(response);
  }

  // Delete employee location
  Future<Map<String, dynamic>> deleteEmployeeLocation(String id) async {
    final url = '${ApiService.baseUrl}/api/employee-locations/$id';
    final headers = await getHeaders();

    final response = await http.delete(Uri.parse(url), headers: headers);
    return handleResponse(response);
  }

  // ==================== Location Validation ====================

  // Validate if coordinates are within allowed locations
  Future<Map<String, dynamic>> validateLocation({
    required double latitude,
    required double longitude,
    required String employeeId,
  }) async {
    final url = '${ApiService.baseUrl}/api/validate-location';
    final headers = await getHeaders();

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'latitude': latitude,
        'longitude': longitude,
        'employeeId': employeeId,
      }),
    );
    return handleResponse(response);
  }
}
