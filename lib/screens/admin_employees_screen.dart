import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/screens/employee_detail_screen.dart';

class AdminEmployeesScreen extends StatefulWidget {
  @override
  _AdminEmployeesScreenState createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, bool> _expandedTiles = {};

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
    if (_searchQuery.isEmpty) {
      return employees;
    }

    final query = _searchQuery.toLowerCase();
    return employees.where((employee) {
      return employee.fullName.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.employeeId.toLowerCase().contains(query) ||
          (employee.designation ?? '').toLowerCase().contains(query) ||
          (employee.department ?? '').toLowerCase().contains(query);
    }).toList();
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
            Icon(Icons.lock, size: 64, color: Colors.grey),
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
                    onPressed: () => _showAddEmployeeDialog(),
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

        // Employee List
        Expanded(
          child: Consumer<EmployeeProvider>(
            builder: (context, employeeProvider, child) {
              // Trigger data load if not already loading and no data
              if (!employeeProvider.isLoading &&
                  employeeProvider.employees.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final provider = Provider.of<EmployeeProvider>(
                      context,
                      listen: false,
                    );
                    provider.getAllEmployees();
                  }
                });
              }

              if (employeeProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (employeeProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading employees',
                        style: AppTextStyles.subheading,
                      ),
                      SizedBox(height: 8),
                      Text(
                        employeeProvider.error!,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshEmployees,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (employeeProvider.employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
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
                        onPressed: () => _showAddEmployeeDialog(),
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

              if (filteredEmployees.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
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
                        'Try adjusting your search query',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshEmployees(),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    120,
                  ), // Bottom padding for nav bar
                  itemCount: filteredEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = filteredEmployees[index];
                    return _buildEmployeeCard(employee);
                  },
                ),
              );
            },
          ),
        ),
      ],
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
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            employee.firstName.substring(0, 1).toUpperCase(),
            style: GoogleFonts.poppins(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          employee.fullName,
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
                onPressed: () => _showEditEmployeeDialog(employee),
                icon: Icon(Icons.edit, size: 16),
                label: Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
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

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddEmployeeDialog(onEmployeeAdded: _refreshEmployees),
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => EditEmployeeDialog(
        employee: employee,
        onEmployeeUpdated: _refreshEmployees,
      ),
    );
  }

  void _confirmDeleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${employee.fullName}? This action cannot be undone.',
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

// Add Employee Dialog
class AddEmployeeDialog extends StatefulWidget {
  final VoidCallback onEmployeeAdded;

  AddEmployeeDialog({required this.onEmployeeAdded});

  @override
  _AddEmployeeDialogState createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();

  String _selectedRole = 'employee';
  DateTime _joinDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Employee',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (!value!.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _employeeIdController,
                              decoration: InputDecoration(
                                labelText: 'Employee ID',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: ['employee', 'admin', 'hr'].map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value!),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _departmentController,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addEmployee,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Add Employee'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      final employeeData = {
        'employeeId': _employeeIdController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'dateOfBirth': DateTime.now().subtract(Duration(days: 25 * 365)),
        'joiningDate': _joinDate,
        'password': 'defaultPassword123',
        'role': _selectedRole,
        'department': _departmentController.text.trim(),
        'address': _addressController.text.trim(),
      };

      final result = await employeeProvider.addEmployee(employeeData);
      if (result['success'] != false) {
        Navigator.pop(context);
        widget.onEmployeeAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _salaryController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }
}

// Edit Employee Dialog
class EditEmployeeDialog extends StatefulWidget {
  final Employee employee;
  final VoidCallback onEmployeeUpdated;

  EditEmployeeDialog({required this.employee, required this.onEmployeeUpdated});

  @override
  _EditEmployeeDialogState createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _departmentController;
  late TextEditingController _designationController;

  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.employee.firstName,
    );
    _lastNameController = TextEditingController(text: widget.employee.lastName);
    _emailController = TextEditingController(text: widget.employee.email);
    _phoneController = TextEditingController(text: widget.employee.mobile);
    _addressController = TextEditingController(
      text: widget.employee.address ?? '',
    );
    _departmentController = TextEditingController(
      text: widget.employee.department ?? '',
    );
    _designationController = TextEditingController(
      text: widget.employee.designation ?? '',
    );
    _selectedRole = widget.employee.role ?? 'employee';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Employee',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _designationController,
                              decoration: InputDecoration(
                                labelText: 'Designation',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['employee', 'admin', 'hr'].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRole = value!),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateEmployee,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Update'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );

      final employeeData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'department': _departmentController.text.trim(),
        'designation': _designationController.text.trim(),
        'role': _selectedRole,
        'address': _addressController.text.trim(),
      };

      final result = await employeeProvider.updateEmployee(
        widget.employee.employeeId,
        employeeData,
      );

      if (result['success'] != false) {
        Navigator.pop(context);
        widget.onEmployeeUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error updating'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }
}
