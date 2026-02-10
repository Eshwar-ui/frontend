import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AddEmployeeScreen extends StatefulWidget {
  final VoidCallback onEmployeeAdded;

  const AddEmployeeScreen({super.key, required this.onEmployeeAdded});

  @override
  _AddEmployeeScreenState createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fathernameController = TextEditingController();
  String? _selectedGender;
  DateTime _dateOfBirth = DateTime.now().subtract(Duration(days: 365 * 25));

  // Professional Info
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _designationController = TextEditingController();
  final _gradeController = TextEditingController();
  final _reportController = TextEditingController();
  String _selectedRole = 'employee';
  DateTime _joiningDate = DateTime.now();

  // Address
  final _addressController = TextEditingController();

  // Bank Info
  final _banknameController = TextEditingController();
  final _accountnumberController = TextEditingController();
  final _ifsccodeController = TextEditingController();

  // Gov IDs
  final _PANnoController = TextEditingController();
  final _UANnoController = TextEditingController();
  final _ESInoController = TextEditingController();

  bool _mobileAccessEnabled = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _fathernameController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _designationController.dispose();
    _gradeController.dispose();
    _reportController.dispose();
    _addressController.dispose();
    _banknameController.dispose();
    _accountnumberController.dispose();
    _ifsccodeController.dispose();
    _PANnoController.dispose();
    _UANnoController.dispose();
    _ESInoController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
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
        'password': _passwordController.text, // Mandatory
        'employeeId': _employeeIdController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'fathername': _fathernameController.text.trim(),
        'gender': _selectedGender,
        'dateOfBirth': _dateOfBirth.toIso8601String(),
        'joiningDate': _joiningDate.toIso8601String(),
        'role': _selectedRole,
        'department': _departmentController.text.trim(),
        'designation': _designationController.text.trim(),
        'grade': _gradeController.text.trim(),
        'report': _reportController.text.trim(),
        'address': _addressController.text.trim(),
        'bankname': _banknameController.text.trim(),
        'accountnumber': _accountnumberController.text.trim(),
        'ifsccode': _ifsccodeController.text.trim(),
        'PANno': _PANnoController.text.trim(),
        'UANno': _UANnoController.text.trim(),
        'ESIno': _ESInoController.text.trim(),
        'mobileAccessEnabled': _mobileAccessEnabled,
        'profileImage': '', // Default empty for now
      };

      final result = await employeeProvider.addEmployee(employeeData);

      if (result['success'] != false) {
        SnackbarUtils.showSuccess(context, 'Employee added successfully');
        widget.onEmployeeAdded();
        Navigator.pop(context);
      } else {
        SnackbarUtils.showError(
          context,
          result['message'] ?? 'Error adding employee',
        );
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add New Employee',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveEmployee,
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Personal Information'),
                    _buildCard([
                      _buildRow([
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'John',
                          mandatory: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'Doe',
                          mandatory: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ]),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'john.doe@example.com',
                        keyboardType: TextInputType.emailAddress,
                        mandatory: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter login password',
                        obscureText: _obscurePassword,
                        mandatory: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+91 9876543210',
                        keyboardType: TextInputType.phone,
                        mandatory: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      _buildTextField(
                        controller: _fathernameController,
                        label: 'Father\'s Name',
                        hint: 'Richard Doe',
                      ),
                      _buildRow([
                        _buildDropdown<String?>(
                          label: 'Gender',
                          value: _selectedGender,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Select'),
                            ),
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedGender = val),
                        ),
                        _buildDatePicker(
                          label: 'Date of Birth',
                          value: _dateOfBirth,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateOfBirth,
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _dateOfBirth = picked);
                            }
                          },
                        ),
                      ]),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader('Professional Information'),
                    _buildCard([
                      _buildRow([
                        _buildTextField(
                          controller: _employeeIdController,
                          label: 'Employee ID',
                          hint: 'QWIT-1001',
                          mandatory: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        _buildDropdown<String>(
                          label: 'Role',
                          value: _selectedRole,
                          items: ['employee', 'admin', 'hr'].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedRole = val!),
                        ),
                      ]),
                      _buildRow([
                        _buildTextField(
                          controller: _departmentController,
                          label: 'Department',
                          hint: 'Engineering',
                        ),
                        _buildTextField(
                          controller: _designationController,
                          label: 'Designation',
                          hint: 'Software Engineer',
                        ),
                      ]),
                      _buildRow([
                        _buildTextField(
                          controller: _gradeController,
                          label: 'Grade',
                          hint: 'L2',
                        ),
                        _buildDatePicker(
                          label: 'Joining Date',
                          value: _joiningDate,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _joiningDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _joiningDate = picked);
                            }
                          },
                        ),
                      ]),
                      _buildTextField(
                        controller: _reportController,
                        label: 'Reporting To',
                        hint: 'Manager Name',
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader('Address'),
                    _buildCard([
                      _buildTextField(
                        controller: _addressController,
                        label: 'Full Address',
                        hint: '123, Main Street, City',
                        maxLines: 3,
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader('Bank Details'),
                    _buildCard([
                      _buildTextField(
                        controller: _banknameController,
                        label: 'Bank Name',
                        hint: 'HDFC Bank',
                      ),
                      _buildTextField(
                        controller: _accountnumberController,
                        label: 'Account Number',
                        hint: '501002345678',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        controller: _ifsccodeController,
                        label: 'IFSC Code',
                        hint: 'HDFC0001234',
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader('Government IDs'),
                    _buildCard([
                      _buildTextField(
                        controller: _PANnoController,
                        label: 'PAN Number',
                        hint: 'ABCDE1234F',
                      ),
                      _buildRow([
                        _buildTextField(
                          controller: _UANnoController,
                          label: 'UAN Number',
                          hint: '100123456789',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          controller: _ESInoController,
                          label: 'ESI Number',
                          hint: '1234567890',
                          keyboardType: TextInputType.number,
                        ),
                      ]),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader('Settings'),
                    _buildCard([
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Enable Mobile Access',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Allow employee to log in via mobile app',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        value: _mobileAccessEnabled,
                        onChanged: (val) =>
                            setState(() => _mobileAccessEnabled = val),
                        secondary: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.phone_android,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ]),
                    SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEmployee,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Employee',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.08,
            ),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.expand((w) => [w, SizedBox(height: 16)]).toList()
          ..removeLast(),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    bool mandatory = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (mandatory)
              Text(
                ' *',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          dropdownColor: colorScheme.surfaceContainerHighest,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd-MM-yyyy').format(value),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          children
              .expand((w) => [Expanded(child: w), SizedBox(width: 12)])
              .toList()
            ..removeLast(),
    );
  }
}
