import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/services/mobile_access_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

enum MobileAccessFilter { all, enabled, disabled }

class AdminMobileAccessScreen extends StatefulWidget {
  const AdminMobileAccessScreen({super.key});

  @override
  State<AdminMobileAccessScreen> createState() =>
      _AdminMobileAccessScreenState();
}

class _AdminMobileAccessScreenState extends State<AdminMobileAccessScreen> {
  final MobileAccessService _mobileAccessService = MobileAccessService();
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  MobileAccessFilter _currentFilter = MobileAccessFilter.all;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final employees = await _mobileAccessService
          .getAllEmployeesMobileAccess();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMobileAccess(String employeeId, bool currentValue) async {
    try {
      await _mobileAccessService.toggleMobileAccess(employeeId, !currentValue);
      SnackbarUtils.showSuccess(
        context,
        'Mobile access ${!currentValue ? 'enabled' : 'disabled'} successfully',
      );
      _loadEmployees(); // Refresh list
    } catch (e) {
      SnackbarUtils.showError(
        context,
        'Failed to update mobile access: ${e.toString()}',
      );
    }
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    return _employees.where((emp) {
      // Search Logic
      final query = _searchQuery.toLowerCase();
      final fullName = (emp['fullName'] ?? '').toString().toLowerCase();
      final email = (emp['email'] ?? '').toString().toLowerCase();
      final employeeId = (emp['employeeId'] ?? '').toString().toLowerCase();
      final matchesSearch = query.isEmpty || 
          fullName.contains(query) ||
          email.contains(query) ||
          employeeId.contains(query);

      // Filter Logic
      final isEnabled = emp['mobileAccessEnabled'] == true;
      bool matchesFilter = true;
      switch (_currentFilter) {
        case MobileAccessFilter.enabled:
          matchesFilter = isEnabled;
          break;
        case MobileAccessFilter.disabled:
          matchesFilter = !isEnabled;
          break;
        case MobileAccessFilter.all:
        default:
          matchesFilter = true;
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
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
          'Mobile Access Management',
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
      ),
      body: Column(
        children: [
          // Filter and Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark ? colorScheme.surfaceContainer : Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainer : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MobileAccessFilter>(
                          value: _currentFilter,
                          icon: Icon(Icons.filter_list),
                          onChanged: (MobileAccessFilter? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _currentFilter = newValue;
                              });
                            }
                          },
                          items: MobileAccessFilter.values.map((MobileAccessFilter filter) {
                            String label;
                            switch (filter) {
                              case MobileAccessFilter.all:
                                label = 'All Users';
                                break;
                              case MobileAccessFilter.enabled:
                                label = 'Access Enabled';
                                break;
                              case MobileAccessFilter.disabled:
                                label = 'Access Disabled';
                                break;
                            }
                            return DropdownMenuItem<MobileAccessFilter>(
                              value: filter,
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading employees',
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
                          onPressed: _loadEmployees,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredEmployees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _currentFilter == MobileAccessFilter.all
                              ? 'No employees found'
                              : 'No matching employees found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredEmployees.length,
                    itemBuilder: (context, index) {
                      final employee = _filteredEmployees[index];
                      final mobileAccessEnabled =
                          employee['mobileAccessEnabled'] == true;

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
                            child: Text(
                              (employee['fullName'] ?? '?')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            employee['fullName'] ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                employee['email'] ?? '',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              Text(
                                employee['employeeId'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: mobileAccessEnabled,
                            onChanged: (value) {
                              _toggleMobileAccess(
                                employee['_id'] ??
                                    employee['id'] ??
                                    employee['employeeId'],
                                mobileAccessEnabled,
                              );
                            },
                            activeColor: colorScheme.primary,
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