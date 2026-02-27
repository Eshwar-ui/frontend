import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/utils/error_handler.dart';
import 'package:quantum_dashboard/widgets/error_widget.dart';
import 'package:quantum_dashboard/screens/employee_detail_screen.dart';
import 'package:quantum_dashboard/screens/add_employee_screen.dart';
import 'package:quantum_dashboard/screens/edit_employee_screen.dart';
import 'package:quantum_dashboard/utils/string_extensions.dart';

class AdminEmployeesScreen extends StatefulWidget {
  @override
  _AdminEmployeesScreenState createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, bool> _expandedTiles = {};

  String _selectedDepartment = 'all';
  String _selectedRole = 'all';
  String _selectedDesignation = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _refreshEmployees() {
    Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
  }

  List<Employee> _filterEmployees(List<Employee> employees) {
    var filtered = employees;

    // Department filter
    if (_selectedDepartment != 'all') {
      filtered = filtered.where((e) {
        final dept = (e.department ?? '').trim();
        if (_selectedDepartment == 'none') return dept.isEmpty;
        return dept.toLowerCase() == _selectedDepartment.toLowerCase();
      }).toList();
    }

    // Role filter
    if (_selectedRole != 'all') {
      filtered = filtered.where((e) {
        final role = (e.role ?? 'employee').toLowerCase();
        return role == _selectedRole.toLowerCase();
      }).toList();
    }

    // Designation filter
    if (_selectedDesignation != 'all') {
      filtered = filtered.where((e) {
        final des = (e.designation ?? '').trim();
        if (_selectedDesignation == 'none') return des.isEmpty;
        return des.toLowerCase() == _selectedDesignation.toLowerCase();
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((employee) {
        return employee.fullName.toLowerCase().contains(query) ||
            employee.email.toLowerCase().contains(query) ||
            employee.employeeId.toLowerCase().contains(query) ||
            (employee.designation ?? '').toLowerCase().contains(query) ||
            (employee.department ?? '').toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  List<String> _getUniqueDepartments(List<Employee> employees) {
    final set = <String>{};
    for (final e in employees) {
      final d = (e.department ?? '').trim();
      if (d.isNotEmpty) set.add(d);
    }
    return set.toList()..sort();
  }

  List<String> _getUniqueDesignations(List<Employee> employees) {
    final set = <String>{};
    for (final e in employees) {
      final d = (e.designation ?? '').trim();
      if (d.isNotEmpty) set.add(d);
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if user is admin
    if (!authProvider.isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text('Access Denied', style: AppTextStyles.subheading),
            SizedBox(height: 8),
            Text(
              'You need admin privileges to access this page.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Custom Header matching new theme
        Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Employees',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Manage your team',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEmployeeScreen(),
                    icon: Icon(Icons.add, size: 20),
                    label: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Search Box
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, ID, designation...',
                    hintStyle: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.poppins(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),

        // Filters and Employee List
        Expanded(
          child: Consumer<EmployeeProvider>(
            builder: (context, employeeProvider, child) {
              if (employeeProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (employeeProvider.error != null) {
                return ErrorStateWidget(
                  title: 'Unable to load employees',
                  message: ErrorHandler.getErrorMessage(employeeProvider.error),
                  onRetry: _refreshEmployees,
                );
              }

              if (employeeProvider.employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Employees Found',
                        style: AppTextStyles.subheading,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This could mean:\n• No employees in database\n• API endpoint issue\n• Check console for details',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEmployeeScreen(),
                        icon: Icon(Icons.add),
                        label: Text('Add Employee'),
                      ),
                      SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _refreshEmployees,
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final filteredEmployees = _filterEmployees(
                employeeProvider.employees,
              );

              bool hasActiveFilters =
                  _searchQuery.isNotEmpty ||
                  _selectedDepartment != 'all' ||
                  _selectedRole != 'all' ||
                  _selectedDesignation != 'all';

              if (filteredEmployees.isEmpty && hasActiveFilters) {
                return Column(
                  children: [
                    _buildFilterRow(
                      employeeProvider.employees,
                      filteredEmployees.length,
                      employeeProvider.employees.length,
                      colorScheme,
                    ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 64,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No employees found',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildFilterRow(
                    employeeProvider.employees,
                    filteredEmployees.length,
                    employeeProvider.employees.length,
                    colorScheme,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _refreshEmployees(),
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                        itemCount: filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          return _buildEmployeeCard(employee);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow(
    List<Employee> employees,
    int filteredCount,
    int totalCount,
    ColorScheme colorScheme,
  ) {
    final departments = _getUniqueDepartments(employees);
    final designations = _getUniqueDesignations(employees);

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Count
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              filteredCount == totalCount
                  ? 'Total: $totalCount employees'
                  : 'Showing $filteredCount of $totalCount employees',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Department filter
                _buildFilterDropdown(
                  label: 'Department',
                  value: _selectedDepartment,
                  items: ['all', 'none', ...departments],
                  displayValues: {
                    'all': 'All Departments',
                    'none': 'No Department',
                    ...{for (var d in departments) d: d},
                  },
                  onChanged: (v) => setState(() => _selectedDepartment = v!),
                  colorScheme: colorScheme,
                ),
                SizedBox(width: 12),
                // Role filter
                _buildFilterDropdown(
                  label: 'Role',
                  value: _selectedRole,
                  items: ['all', 'employee', 'admin', 'hr'],
                  displayValues: {
                    'all': 'All Roles',
                    'employee': 'Employee',
                    'admin': 'Admin',
                    'hr': 'HR',
                  },
                  onChanged: (v) => setState(() => _selectedRole = v!),
                  colorScheme: colorScheme,
                ),
                SizedBox(width: 12),
                // Designation filter
                _buildFilterDropdown(
                  label: 'Designation',
                  value: _selectedDesignation,
                  items: ['all', 'none', ...designations],
                  displayValues: {
                    'all': 'All Designations',
                    'none': 'No Designation',
                    ...{for (var d in designations) d: d},
                  },
                  onChanged: (v) => setState(() => _selectedDesignation = v!),
                  colorScheme: colorScheme,
                ),
                if (_selectedDepartment != 'all' ||
                    _selectedRole != 'all' ||
                    _selectedDesignation != 'all') ...[
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDepartment = 'all';
                        _selectedRole = 'all';
                        _selectedDesignation = 'all';
                      });
                    },
                    icon: Icon(
                      Icons.clear,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    tooltip: 'Clear filters',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Map<String, String> displayValues,
    required ValueChanged<String?> onChanged,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : 'all',
          isExpanded: false,
          isDense: true,
          menuMaxHeight: 300,
          dropdownColor: colorScheme.surfaceContainerHighest,
          hint: Text(label, style: GoogleFonts.poppins(fontSize: 13)),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                displayValues[item] ?? item,
                style: GoogleFonts.poppins(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedTiles[employee.id] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedTiles[employee.id] = expanded;
          });
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Text(
            (employee.firstName.isNotEmpty
                    ? employee.firstName.substring(0, 1)
                    : employee.fullName.isNotEmpty
                    ? employee.fullName.substring(0, 1)
                    : '?')
                .toUpperCase(),
            style: GoogleFonts.poppins(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          employee.fullName.toTitleCase(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          employee.designation ?? 'No Designation',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.visibility),
              color: colorScheme.primary,
              onPressed: () => _navigateToDetailScreen(employee),
              tooltip: 'View Details',
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
        children: [
          Divider(color: colorScheme.outline.withOpacity(0.1)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: employee.email,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.badge_outlined,
                  label: 'ID',
                  value: employee.employeeId,
                ),
              ),
            ],
          ),
          if (employee.department != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.business_outlined,
                    label: 'Department',
                    value: employee.department!,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Mobile',
                    value: employee.mobile,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditEmployee(employee),
                icon: Icon(Icons.edit, size: 16),
                label: Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
              // SizedBox(width: 8),
              // TextButton.icon(
              //   onPressed: () => _showResetPasswordDialog(employee),
              //   icon: Icon(Icons.lock_reset, size: 16),
              //   label: Text('Reset Password'),
              //   style: TextButton.styleFrom(
              //     foregroundColor: Colors.orange.shade700,
              //   ),
              // ),
              SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDeleteEmployee(employee),
                icon: Icon(Icons.delete_outline, size: 16),
                label: Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDetailScreen(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailScreen(employee: employee),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddEmployeeScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEmployeeScreen(onEmployeeAdded: _refreshEmployees),
      ),
    );
  }

  void _showEditEmployee(Employee employee) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditEmployeeScreen(
          employee: employee,
          onEmployeeUpdated: _refreshEmployees,
        ),
      ),
    );
  }

  void _showResetPasswordDialog(Employee employee) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reset Password'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset password for ${employee.fullName.toTitleCase()} (${employee.employeeId})',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'New password is required';
                      }
                      if (value.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please confirm password';
                      }
                      if (value.trim() != newPasswordController.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                    },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                      });

                      final authProvider = Provider.of<AuthProvider>(
                        this.context,
                        listen: false,
                      );
                      final result = await authProvider.adminResetPassword(
                        employee.employeeId,
                        newPasswordController.text.trim(),
                        confirmPasswordController.text.trim(),
                      );

                      if (!mounted) {
                        return;
                      }

                      if (result['success'] == true) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Password reset successfully for ${employee.fullName.toTitleCase()}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                        });
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  'Failed to reset password. Please try again.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Reset Password'),
            ),
          ],
        ),
      ),
    ).then((_) {
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  void _confirmDeleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${employee.fullName.toTitleCase()}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEmployee(employee);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(Employee employee) async {
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      final result = await employeeProvider.deleteEmployee(employee.employeeId);

      if (result['success'] != false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshEmployees();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error deleting employee'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting employee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
