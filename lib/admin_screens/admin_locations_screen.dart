import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/company_location_model.dart';
import 'package:quantum_dashboard/models/employee_location_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/services/attendance_settings_service.dart';
import 'package:quantum_dashboard/services/location_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';
import 'package:quantum_dashboard/utils/string_extensions.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends State<AdminLocationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocationService _locationService = LocationService();
  final AttendanceSettingsService _attendanceSettingsService =
      AttendanceSettingsService();

  // Company Locations State
  List<CompanyLocation> _companyLocations = [];
  bool _isCompanyLoading = false;
  String? _companyError;

  // Employee Locations State
  List<EmployeeLocation> _employeeLocations = [];
  String? _selectedEmployeeId;
  bool _isEmployeeLoading = false;
  String? _employeeError;
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final FocusNode _employeeSearchFocusNode = FocusNode();

  bool _locationPunchInEnabled = true;
  bool _isSettingsLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _employeeSearchFocusNode.addListener(_onEmployeeSearchFocusChange);
    _employeeSearchController.addListener(_onEmployeeSearchFocusChange);
    _loadCompanyLocations();
    _loadAttendanceSettings();
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
    _tabController.dispose();
    super.dispose();
  }

  void _onEmployeeSearchFocusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAttendanceSettings() async {
    if (!mounted) return;
    setState(() => _isSettingsLoading = true);
    try {
      final enabled =
          await _attendanceSettingsService.getLocationPunchInEnabled();
      if (mounted) {
        setState(() {
          _locationPunchInEnabled = enabled;
          _isSettingsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSettingsLoading = false);
        SnackbarUtils.showError(
          context,
          'Failed to load attendance settings: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _toggleLocationPunchIn(bool value) async {
    if (!mounted) return;
    setState(() => _isSettingsLoading = true);
    try {
      final enabled =
          await _attendanceSettingsService.updateLocationPunchInEnabled(value);
      if (mounted) {
        setState(() {
          _locationPunchInEnabled = enabled;
          _isSettingsLoading = false;
        });
        SnackbarUtils.showSuccess(
          context,
          enabled
              ? 'Location-based punch enabled'
              : 'Location-based punch disabled',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSettingsLoading = false);
        SnackbarUtils.showError(
          context,
          'Failed to update setting: ${e.toString()}',
        );
      }
    }
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

  // --- Company Locations Logic ---
  Future<void> _loadCompanyLocations() async {
    if (!mounted) return;
    setState(() {
      _isCompanyLoading = true;
      _companyError = null;
    });

    try {
      final locations = await _locationService.getCompanyLocations();
      if (mounted) {
        setState(() {
          _companyLocations = locations;
          _isCompanyLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _companyError = e.toString();
          _isCompanyLoading = false;
        });
      }
    }
  }

  Future<void> _addCompanyLocation() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

    final result = await _showLocationDialog(
      title: 'Add Office Location',
      nameController: nameController,
      addressController: addressController,
      latController: latitudeController,
      longController: longitudeController,
      buttonText: 'Add',
    );

    if (result == true) {
      try {
        await _locationService.createCompanyLocation(
          name: nameController.text.trim(),
          address: addressController.text.trim(),
          latitude: double.parse(latitudeController.text.trim()),
          longitude: double.parse(longitudeController.text.trim()),
        );
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Office location added successfully',
          );
          _loadCompanyLocations();
        }
      } catch (e) {
        if (mounted)
          SnackbarUtils.showError(
            context,
            'Failed to add location: ${e.toString()}',
          );
      }
    }
  }

  Future<void> _editCompanyLocation(CompanyLocation location) async {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final latitudeController = TextEditingController(
      text: location.latitude.toString(),
    );
    final longitudeController = TextEditingController(
      text: location.longitude.toString(),
    );

    final result = await _showLocationDialog(
      title: 'Edit Office Location',
      nameController: nameController,
      addressController: addressController,
      latController: latitudeController,
      longController: longitudeController,
      buttonText: 'Update',
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
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Office location updated successfully',
          );
          _loadCompanyLocations();
        }
      } catch (e) {
        if (mounted)
          SnackbarUtils.showError(
            context,
            'Failed to update location: ${e.toString()}',
          );
      }
    }
  }

  Future<void> _deleteCompanyLocation(CompanyLocation location) async {
    final confirmed = await _showDeleteConfirmation(location.name);
    if (confirmed == true) {
      try {
        await _locationService.deleteCompanyLocation(location.id);
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Office location deleted successfully',
          );
          _loadCompanyLocations();
        }
      } catch (e) {
        if (mounted)
          SnackbarUtils.showError(
            context,
            'Failed to delete location: ${e.toString()}',
          );
      }
    }
  }

  // --- Employee Locations Logic ---
  Future<void> _loadEmployees() async {
    if (!mounted) return;
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      await employeeProvider.getAllEmployees();
    } catch (e) {
      if (mounted)
        SnackbarUtils.showError(
          context,
          'Failed to load employees: ${e.toString()}',
        );
    }
  }

  Future<void> _loadEmployeeLocations() async {
    if (_selectedEmployeeId == null) {
      setState(() => _employeeLocations = []);
      return;
    }

    setState(() {
      _isEmployeeLoading = true;
      _employeeError = null;
    });

    try {
      final locations = await _locationService.getEmployeeLocations(
        _selectedEmployeeId!,
      );
      if (mounted) {
        setState(() {
          _employeeLocations = locations;
          _isEmployeeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _employeeError = e.toString();
          _isEmployeeLoading = false;
        });
      }
    }
  }

  Future<void> _addEmployeeLocation() async {
    if (_selectedEmployeeId == null) {
      SnackbarUtils.showError(context, 'Please select an employee first');
      return;
    }

    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latitudeController = TextEditingController();
    final longitudeController = TextEditingController();

    final result = await _showLocationDialog(
      title: 'Add Employee Location',
      nameController: nameController,
      addressController: addressController,
      latController: latitudeController,
      longController: longitudeController,
      buttonText: 'Add',
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
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Employee location added successfully',
          );
          _loadEmployeeLocations();
        }
      } catch (e) {
        if (mounted)
          SnackbarUtils.showError(
            context,
            'Failed to add location: ${e.toString()}',
          );
      }
    }
  }

  Future<void> _editEmployeeLocation(EmployeeLocation location) async {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final latitudeController = TextEditingController(
      text: location.latitude.toString(),
    );
    final longitudeController = TextEditingController(
      text: location.longitude.toString(),
    );

    final result = await _showLocationDialog(
      title: 'Edit Employee Location',
      nameController: nameController,
      addressController: addressController,
      latController: latitudeController,
      longController: longitudeController,
      buttonText: 'Update',
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
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Employee location updated successfully',
          );
          _loadEmployeeLocations();
        }
      } catch (e) {
        if (mounted)
          SnackbarUtils.showError(
            context,
            'Failed to update location: ${e.toString()}',
          );
      }
    }
  }

  Future<void> _deleteEmployeeLocation(EmployeeLocation location) async {
    final confirmed = await _showDeleteConfirmation(location.name);
    if (confirmed == true) {
      try {
        await _locationService.deleteEmployeeLocation(location.id);
        if (mounted) {
          SnackbarUtils.showSuccess(
            context,
            'Employee location deleted successfully',
          );
          _loadEmployeeLocations();
        }
      } catch (e) {
        if (mounted)
          SnackbarUtils.showError(
            context,
            'Failed to delete location: ${e.toString()}',
          );
      }
    }
  }

  // --- Dialogs ---
  Future<bool?> _showLocationDialog({
    required String title,
    required TextEditingController nameController,
    required TextEditingController addressController,
    required TextEditingController latController,
    required TextEditingController longController,
    required String buttonText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                nameController,
                'Location Name',
                'e.g., Head Office / Home',
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                addressController,
                'Address',
                'Street, City, State',
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                latController,
                'Latitude',
                'e.g., 17.4483',
                isNumeric: true,
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                longController,
                'Longitude',
                'e.g., 78.3919',
                isNumeric: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty &&
                  latController.text.isNotEmpty &&
                  longController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumeric = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
    );
  }

  Future<bool?> _showDeleteConfirmation(String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Location Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Provider.of<NavigationProvider>(
            context,
            listen: false,
          ).setCurrentPage(NavigationPage.Dashboard),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              text: 'OFFICE',
              icon: Icon(Icons.location_city_rounded, size: 22),
            ),
            Tab(
              text: 'EMPLOYEE',
              icon: Icon(Icons.person_pin_circle_rounded, size: 22),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.index == 0
            ? _addCompanyLocation()
            : _addEmployeeLocation(),
        backgroundColor: colorScheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: Text(
          'Add New',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [colorScheme.primary.withOpacity(0.05), Colors.transparent]
                : [colorScheme.primary.withOpacity(0.03), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location-Based Punch',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _locationPunchInEnabled
                                ? 'Users must punch in from office or approved locations'
                                : 'Users can punch in from anywhere',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isSettingsLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Switch(
                        value: _locationPunchInEnabled,
                        onChanged: _toggleLocationPunchIn,
                        activeTrackColor: colorScheme.primary.withValues(alpha: 0.5),
                        activeThumbColor: colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCompanyLocationsTab(colorScheme),
                  _buildEmployeeLocationsTab(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLocationsTab(ColorScheme colorScheme) {
    if (_isCompanyLoading)
      return const Center(child: CircularProgressIndicator());
    if (_companyError != null)
      return _buildErrorState(_companyError!, _loadCompanyLocations);
    if (_companyLocations.isEmpty)
      return _buildEmptyState(
        'No office locations found',
        'Add a location to get started',
      );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _companyLocations.length,
      itemBuilder: (context, index) => _buildLocationCard(
        colorScheme,
        _companyLocations[index].name,
        _companyLocations[index].address,
        _companyLocations[index].latitude,
        _companyLocations[index].longitude,
        onEdit: () => _editCompanyLocation(_companyLocations[index]),
        onDelete: () => _deleteCompanyLocation(_companyLocations[index]),
        isOffice: true,
      ),
    );
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
                      _loadEmployeeLocations();
                    },
                    tooltip: 'Clear selection',
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: colorScheme.surface,
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
                        '${emp.employeeId} - ${emp.fullName.toTitleCase()}',
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
                              '${emp.employeeId} - ${emp.fullName.toTitleCase()}';
                        });
                        _employeeSearchFocusNode.unfocus();
                        _loadEmployeeLocations();
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

  Widget _buildEmployeeLocationsTab(ColorScheme colorScheme) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: _buildEmployeeSearch(colorScheme, employeeProvider, isDark),
        ),
        Expanded(
          child: _selectedEmployeeId == null
              ? _buildEmptyState(
                  'Select an employee',
                  'Choose an employee to manage their allowed locations',
                  icon: Icons.person_pin_outlined,
                )
              : _isEmployeeLoading
              ? const Center(child: CircularProgressIndicator())
              : _employeeError != null
              ? _buildErrorState(_employeeError!, _loadEmployeeLocations)
              : _employeeLocations.isEmpty
              ? _buildEmptyState(
                  'No locations found',
                  'Add a home/work location for this employee',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _employeeLocations.length,
                  itemBuilder: (context, index) => _buildLocationCard(
                    colorScheme,
                    _employeeLocations[index].name,
                    _employeeLocations[index].address,
                    _employeeLocations[index].latitude,
                    _employeeLocations[index].longitude,
                    onEdit: () =>
                        _editEmployeeLocation(_employeeLocations[index]),
                    onDelete: () =>
                        _deleteEmployeeLocation(_employeeLocations[index]),
                    isOffice: false,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    ColorScheme colorScheme,
    String title,
    String address,
    double lat,
    double long, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required bool isOffice,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isOffice
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          child: Icon(
            isOffice ? Icons.location_city : Icons.home,
            color: isOffice ? colorScheme.primary : colorScheme.secondary,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(address, style: GoogleFonts.poppins(fontSize: 12)),
            Text(
              '${lat.toStringAsFixed(6)}, ${long.toStringAsFixed(6)}',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: colorScheme.primary, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: colorScheme.error, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle, {
    IconData icon = Icons.location_off_rounded,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
