import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/models/head_office_location_model.dart';
import 'package:quantum_dashboard/providers/location_provider.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';

class AddHeadOfficeLocationScreen extends StatefulWidget {
  @override
  _AddHeadOfficeLocationScreenState createState() =>
      _AddHeadOfficeLocationScreenState();
}

class _AddHeadOfficeLocationScreenState
    extends State<AddHeadOfficeLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingLocation = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _locationNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _errorMessage = null;
    });

    try {
      var status = await Permission.location.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
        });
      } else if (status.isDenied) {
        setState(() {
          _errorMessage =
              'Location permission is denied. Please grant permission to use this feature.';
        });
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _errorMessage =
              'Location permission is permanently denied. Please open app settings to grant permission.';
        });
        await openAppSettings();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get current location. Please try again.';
      });
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _clearMessages();
    setState(() {
      _isLoading = true;
    });

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);

    final newLocation = HeadOfficeLocation(
      name: _locationNameController.text,
      address: _addressController.text,
      latitude: double.parse(_latitudeController.text),
      longitude: double.parse(_longitudeController.text),
    );

    try {
      await locationProvider.addLocation(newLocation);

      setState(() {
        _successMessage = 'Head Office Location added successfully!';
        _locationNameController.clear();
        _addressController.clear();
        _latitudeController.clear();
        _longitudeController.clear();
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while saving. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: Text('Head Office Location has been added successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: (_) => _clearMessages(),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Add Head Office Location'), elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32),
              CustomFloatingContainer(
                child: Column(
                  spacing: 12,
                  children: [
                    _buildTextField(
                      controller: _locationNameController,
                      label: 'Location Name',
                      hint: 'Enter head office location name',
                      validator: (value) =>
                          _validateRequired(value, 'Location Name'),
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter full address',
                      validator: (value) => _validateRequired(value, 'Address'),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                        icon: _isFetchingLocation
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Icon(Icons.my_location),
                        label: Text(_isFetchingLocation
                            ? 'Fetching Location...'
                            : 'Auto-fill with Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      hint: 'Enter latitude (e.g., 34.0522)',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => _validateNumeric(value, 'Latitude'),
                    ),
                    _buildTextField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      hint: 'Enter longitude (e.g., -118.2437)',
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          _validateNumeric(value, 'Longitude'),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.error.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_successMessage != null) ...[
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Saving Location...'),
                          ],
                        )
                      : Text(
                          'Save Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
