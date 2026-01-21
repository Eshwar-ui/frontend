import 'package:flutter/material.dart';
import 'package:quantum_dashboard/models/company_location_model.dart';
import 'package:quantum_dashboard/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  List<CompanyLocation> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CompanyLocation> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLocations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _locations = await _locationService.getCompanyLocations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLocation({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _locationService.createCompanyLocation(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      // Refresh locations after adding
      await fetchLocations();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
