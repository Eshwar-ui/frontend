import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/company_location_model.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/services/location_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminCompanyLocationsScreen extends StatefulWidget {
  const AdminCompanyLocationsScreen({super.key});

  @override
  State<AdminCompanyLocationsScreen> createState() => _AdminCompanyLocationsScreenState();
}

class _AdminCompanyLocationsScreenState extends State<AdminCompanyLocationsScreen> {
  final LocationService _locationService = LocationService();
  List<CompanyLocation> _locations = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locations = await _locationService.getCompanyLocations();
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addLocation() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Company Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Head Office',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., Hyderabad',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: latitudeController,
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g., 17.4483265',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: longitudeController,
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g., 78.3919326',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty &&
                  latitudeController.text.isNotEmpty &&
                  longitudeController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _locationService.createCompanyLocation(
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          latitude: double.parse(latitudeController.text.trim()),
          longitude: double.parse(longitudeController.text.trim()),
        );
        SnackbarUtils.showSuccess(context, 'Company location added successfully');
        _loadLocations();
      } catch (e) {
        SnackbarUtils.showError(context, 'Failed to add location: ${e.toString()}');
      }
    }
  }

  Future<void> _editLocation(CompanyLocation location) async {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final latitudeController = TextEditingController(text: location.latitude.toString());
    final longitudeController = TextEditingController(text: location.longitude.toString());

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Company Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: latitudeController,
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: longitudeController,
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty &&
                  latitudeController.text.isNotEmpty &&
                  longitudeController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _locationService.updateCompanyLocation(
          id: location.id,
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          latitude: double.parse(latitudeController.text.trim()),
          longitude: double.parse(longitudeController.text.trim()),
        );
        SnackbarUtils.showSuccess(context, 'Company location updated successfully');
        _loadLocations();
      } catch (e) {
        SnackbarUtils.showError(context, 'Failed to update location: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteLocation(CompanyLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _locationService.deleteCompanyLocation(location.id);
        SnackbarUtils.showSuccess(context, 'Company location deleted successfully');
        _loadLocations();
      } catch (e) {
        SnackbarUtils.showError(context, 'Failed to delete location: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Company Locations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<NavigationProvider>(context, listen: false)
                .setCurrentPage(NavigationPage.Dashboard);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addLocation,
            tooltip: 'Add Location',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading locations',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLocations,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No company locations',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add a location to get started',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Icon(Icons.location_on, color: Colors.white),
                            ),
                            title: Text(
                              location.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  location.address,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                                Text(
                                  '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  color: colorScheme.primary,
                                  onPressed: () => _editLocation(location),
                                  tooltip: 'Edit Location',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  color: colorScheme.error,
                                  onPressed: () => _deleteLocation(location),
                                  tooltip: 'Delete Location',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

