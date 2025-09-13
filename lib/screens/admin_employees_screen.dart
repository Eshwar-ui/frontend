import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

class AdminEmployeesScreen extends StatefulWidget {
  @override
  _AdminEmployeesScreenState createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
    });
  }

  void _refreshEmployees() {
    Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check if user is admin
    if (!authProvider.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: AppTextStyles.subheading,
              ),
              SizedBox(height: 8),
              Text(
                'You need admin privileges to access this page.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Employee Management',
                      style: AppTextStyles.subheading.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEmployeeDialog(),
                    icon: Icon(Icons.add, size: 20),
                    label: Text('Add Employee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Employee List
          Expanded(
            child: Consumer<EmployeeProvider>(
              builder: (context, employeeProvider, child) {
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _refreshEmployees(),
                  child: _buildEmployeeList(employeeProvider.employees),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(List<Employee> employees) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF1976D2),
                  child: Text(
                    employee.firstName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: AppTextStyles.subheading.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${employee.employeeId}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: employee.status == 'active' ? Colors.green : Colors.red,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Text(
                //     employee.status == 'active' ? 'Active' : 'Inactive',
                //     style: TextStyle(
                //       color: Colors.white,
                //       fontSize: 10,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.email,
                    label: 'Email',
                    value: employee.email,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.work,
                    label: 'Role',
                    value: employee.role?.toUpperCase() ?? 'N/A',
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.business,
                    label: 'Department',
                    value: employee.department ?? 'N/A',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.badge,
                    label: 'Designation',
                    value: employee.designation??'N/A',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditEmployeeDialog(employee),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF1976D2),
                      side: BorderSide(color: Color(0xFF1976D2)),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeleteEmployee(employee),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
      builder: (context) => AddEmployeeDialog(
        onEmployeeAdded: _refreshEmployees,
      ),
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
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
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
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Employee',
              style: AppTextStyles.subheading.copyWith(
                fontSize: 18,
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
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
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
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                              ),
                              items: ['employee', 'admin', 'hr'].map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedRole = value!),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _designationController,
                              decoration: InputDecoration(
                                labelText: 'Designation',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController,
                              decoration: InputDecoration(
                                labelText: 'Salary',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true 
                          ? 'Required' : null,
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
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addEmployee,
                    child: _isLoading 
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Add Employee'),
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
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      
      final employeeData = {
        'employeeId': _employeeIdController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'dateOfBirth': DateTime.now().subtract(Duration(days: 25 * 365)), // Default age 25
        'joiningDate': _joinDate,
        'password': 'defaultPassword123', // Default password
        'profileImage': '',
        'department': _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        'designation': _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
        'role': _selectedRole,
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      };

      final result = await employeeProvider.addEmployee(employeeData);

      if (result['success'] != false) {
        Navigator.pop(context);
        widget.onEmployeeAdded();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error adding employee'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding employee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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

// Edit Employee Dialog (similar structure, just for updating)
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
  late TextEditingController _salaryController;
  late TextEditingController _departmentController;
  late TextEditingController _designationController;
  
  late String _selectedRole;
  bool _isLoading = false;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.employee.firstName);
    _lastNameController = TextEditingController(text: widget.employee.lastName);
    _emailController = TextEditingController(text: widget.employee.email);
    _phoneController = TextEditingController(text: widget.employee.mobile);
    _addressController = TextEditingController(text: widget.employee.address ?? '');
    _salaryController = TextEditingController(text: '0'); // Salary field removed from model
    _departmentController = TextEditingController(text: widget.employee.department ?? '');
    _designationController = TextEditingController(text: widget.employee.designation ?? '');
    _selectedRole = widget.employee.role ?? 'employee';
    _isActive = true; // isActive field removed from model
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Employee',
              style: AppTextStyles.subheading.copyWith(
                fontSize: 18,
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
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
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
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                              ),
                              items: ['employee', 'admin', 'hr'].map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedRole = value!),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              title: Text('Active'),
                              value: _isActive,
                              onChanged: (value) => setState(() => _isActive = value),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _designationController,
                              decoration: InputDecoration(
                                labelText: 'Designation',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController,
                              decoration: InputDecoration(
                                labelText: 'Salary',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty ?? true 
                                ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true 
                          ? 'Required' : null,
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
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateEmployee,
                    child: _isLoading 
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Update'),
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
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      
      final employeeData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'department': _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
        'designation': _designationController.text.trim().isEmpty ? null : _designationController.text.trim(),
        'role': _selectedRole,
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      };

      final result = await employeeProvider.updateEmployee(widget.employee.employeeId, employeeData);

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
            content: Text(result['message'] ?? 'Error updating employee'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating employee: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
    _departmentController.dispose();
    _designationController.dispose();
    super.dispose();
  }
}
