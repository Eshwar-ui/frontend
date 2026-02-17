import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/employee_location_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/services/location_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminEmployeeLocationsScreen extends StatefulWidget {
  const AdminEmployeeLocationsScreen({super.key});

  @override
  State<AdminEmployeeLocationsScreen> createState() =>
      _AdminEmployeeLocationsScreenState();
}

class _AdminEmployeeLocationsScreenState
    extends State<AdminEmployeeLocationsScreen> {
  final LocationService _locationService = LocationService();
  List<EmployeeLocation> _locations = [];
  String? _selectedEmployeeId;
  bool _isLoading = false;
  String? _error;
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final FocusNode _employeeSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _employeeSearchFocusNode.addListener(_onEmployeeSearchFocusChange);
    _employeeSearchController.addListener(_onEmployeeSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployees();
    });
  }

  @override
  void dispose() {
    _employeeSearchController.removeListener(_onEmployeeSearchFocusChange);
    _employeeSearchController.dispose();
    _employeeSearchFocusNode.removeListener(_onEmployeeSearchFocusChange);
    _employeeSearchFocusNode.dispose();
    super.dispose();
  }

  void _onEmployeeSearchFocusChange() {
    if (mounted) setState(() {});
  }

  List<Employee> _getFilteredEmployees(
    EmployeeProvider employeeProvider,
    String query,
  ) {
    if (query.isEmpty) return employeeProvider.employees;
    final q = query.trim().toLowerCase();
    return employeeProvider.employees.where((e) {
      return e.fullName.toLowerCase().contains(q) ||
          e.employeeId.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      await employeeProvider.getAllEmployees();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to load employees: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _loadLocations() async {
    if (_selectedEmployeeId == null) {
      setState(() => _locations = []);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final locations = await _locationService.getEmployeeLocations(
        _selectedEmployeeId!,
      );
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
    if (_selectedEmployeeId == null) {
      SnackbarUtils.showError(context, 'Please select an employee first');
      return;
    }

    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Employee Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Home',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., Home address',
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
        await _locationService.createEmployeeLocation(
          employeeId: _selectedEmployeeId!,
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          latitude: double.parse(latitudeController.text.trim()),
          longitude: double.parse(longitudeController.text.trim()),
        );
        SnackbarUtils.showSuccess(
          context,
          'Employee location added successfully',
        );
        _loadLocations();
      } catch (e) {
        SnackbarUtils.showError(
          context,
          'Failed to add location: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _editLocation(EmployeeLocation location) async {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final latitudeController = TextEditingController(
      text: location.latitude.toString(),
    );
    final longitudeController = TextEditingController(
      text: location.longitude.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Employee Location'),
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
        await _locationService.updateEmployeeLocation(
          id: location.id,
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          latitude: double.parse(latitudeController.text.trim()),
          longitude: double.parse(longitudeController.text.trim()),
        );
        SnackbarUtils.showSuccess(
          context,
          'Employee location updated successfully',
        );
        _loadLocations();
      } catch (e) {
        SnackbarUtils.showError(
          context,
          'Failed to update location: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteLocation(EmployeeLocation location) async {
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
        await _locationService.deleteEmployeeLocation(location.id);
        SnackbarUtils.showSuccess(
          context,
          'Employee location deleted successfully',
        );
        _loadLocations();
      } catch (e) {
        SnackbarUtils.showError(
          context,
          'Failed to delete location: ${e.toString()}',
        );
      }
    }
  }

  Widget _buildEmployeeSearch(
    ColorScheme colorScheme,
    EmployeeProvider employeeProvider,
    bool isDark,
  ) {
    final query = _employeeSearchController.text.trim();
    final showList = _employeeSearchFocusNode.hasFocus;
    final filtered = _getFilteredEmployees(employeeProvider, query);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _employeeSearchController,
          focusNode: _employeeSearchFocusNode,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Select Employee',
            hintText: 'Search by name or ID...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
            suffixIcon: _selectedEmployeeId != null
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedEmployeeId = null;
                        _employeeSearchController.clear();
                      });
                      _loadLocations();
                    },
                    tooltip: 'Clear selection',
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          onTap: () {
            if (_selectedEmployeeId != null) {
              _employeeSearchController.clear();
              setState(() => _selectedEmployeeId = null);
            }
          },
        ),
        if (showList) ...[
          SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ...filtered.map((emp) {
                    final isSelected = _selectedEmployeeId == emp.employeeId;
                    return ListTile(
                      leading: Icon(
                        Icons.person_outline,
                        size: 22,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      title: Text(
                        '${emp.employeeId} - ${emp.fullName}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedEmployeeId = emp.employeeId;
                          _employeeSearchController.text =
                              '${emp.employeeId} - ${emp.fullName}';
                        });
                        _employeeSearchFocusNode.unfocus();
                        _loadLocations();
                      },
                    );
                  }),
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No employees match "$query"',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Employee Locations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<NavigationProvider>(
              context,
              listen: false,
            ).setCurrentPage(NavigationPage.Dashboard);
          },
        ),
        actions: [
          if (_selectedEmployeeId != null)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addLocation,
              tooltip: 'Add Location',
            ),
        ],
      ),
      body: Column(
        children: [
          // Employee search selector
          Container(
            padding: EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: _buildEmployeeSearch(colorScheme, employeeProvider, isDark),
          ),
          // Locations list
          Expanded(
            child: _selectedEmployeeId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Select an employee to manage locations',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _isLoading
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
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No locations for this employee',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a location to enable work-from-home',
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
                            backgroundColor: colorScheme.secondary,
                            child: Icon(Icons.home, color: Colors.white),
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
          ),
        ],
      ),
    );
  }
}
