import 'package:flutter/material.dart';
import 'package:quantum_dashboard/models/head_office_location_model.dart';
import 'package:quantum_dashboard/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  List<HeadOfficeLocation> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HeadOfficeLocation> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLocations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _locations = await _locationService.getHeadOfficeLocations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLocation(HeadOfficeLocation location) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newLocation = await _locationService.addHeadOfficeLocation(location);
      _locations.add(newLocation);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
