import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quantum_dashboard/models/head_office_location_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class LocationService extends ApiService {
  // Fetch all head office locations
  Future<List<HeadOfficeLocation>> getHeadOfficeLocations() async {
    // TODO: Replace with actual API call
    // For now, return a mocked list
    await Future.delayed(Duration(seconds: 1));
    return [
      HeadOfficeLocation(
        id: '1',
        name: 'Quantum Works HQ',
        address: '123 Quantum Street, Innovation City',
        latitude: 34.0522,
        longitude: -118.2437,
      ),
      HeadOfficeLocation(
        id: '2',
        name: 'Quantum Works Branch Office',
        address: '456 Tech Park Avenue, Silicon Valley',
        latitude: 37.3861,
        longitude: -122.0839,
      ),
    ];

    /*
    // Actual API call implementation
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/locations'),
      headers: await getHeaders(),
    );

    final data = handleResponse(response);
    return (data as List)
        .map((json) => HeadOfficeLocation.fromJson(json))
        .toList();
    */
  }

  // Add a new head office location
  Future<HeadOfficeLocation> addHeadOfficeLocation(HeadOfficeLocation location) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/locations'),
      headers: await getHeaders(),
      body: json.encode(location.toJson()),
    );

    final data = handleResponse(response);
    return HeadOfficeLocation.fromJson(data);
  }
}
