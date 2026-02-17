import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class EditEmployeeScreen extends StatefulWidget {
  final Employee employee;
  final VoidCallback onEmployeeUpdated;

  const EditEmployeeScreen({
    super.key,
    required this.employee,
    required this.onEmployeeUpdated,
  });

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _departmentController;
  late TextEditingController _designationController;
  late TextEditingController _gradeController;
  late TextEditingController _banknameController;
  late TextEditingController _accountnumberController;
  late TextEditingController _ifsccodeController;
  late TextEditingController _PANnoController;
  late TextEditingController _UANnoController;
  late TextEditingController _ESInoController;
  late TextEditingController _fathernameController;

  late String _selectedRole;
  late String? _selectedGender;
  late DateTime _dateOfBirth;
  late DateTime _joiningDate;
  late bool _mobileAccessEnabled;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.employee.firstName);
    _lastNameController = TextEditingController(text: widget.employee.lastName);
    _emailController = TextEditingController(text: widget.employee.email);
    _phoneController = TextEditingController(text: widget.employee.mobile);
    _addressController = TextEditingController(text: widget.employee.address ?? '');
    _departmentController = TextEditingController(text: widget.employee.department ?? '');
    _designationController = TextEditingController(text: widget.employee.designation ?? '');
    _gradeController = TextEditingController(text: widget.employee.grade ?? '');
    _banknameController = TextEditingController(text: widget.employee.bankname ?? '');
    _accountnumberController = TextEditingController(text: widget.employee.accountnumber ?? '');
    _ifsccodeController = TextEditingController(text: widget.employee.ifsccode ?? '');
    _PANnoController = TextEditingController(text: widget.employee.PANno ?? '');
    _UANnoController = TextEditingController(text: widget.employee.UANno ?? '');
    _ESInoController = TextEditingController(text: widget.employee.ESIno ?? '');
    _fathernameController = TextEditingController(text: widget.employee.fathername ?? '');
    _selectedRole = (widget.employee.role ?? 'employee').toLowerCase();
    _selectedGender = widget.employee.gender;
    _dateOfBirth = widget.employee.dateOfBirth;
    _joiningDate = widget.employee.joiningDate;
    _mobileAccessEnabled = widget.employee.mobileAccessEnabled ?? false;
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
    _gradeController.dispose();
    _banknameController.dispose();
    _accountnumberController.dispose();
    _ifsccodeController.dispose();
    _PANnoController.dispose();
    _UANnoController.dispose();
    _ESInoController.dispose();
    _fathernameController.dispose();
    super.dispose();
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
        'department': _departmentController.text.trim(),
        'designation': _designationController.text.trim(),
        'role': _selectedRole,
        'gender': _selectedGender,
        'grade': _gradeController.text.trim(),
        'dateOfBirth': _dateOfBirth.toIso8601String(),
        'joiningDate': _joiningDate.toIso8601String(),
        'address': _addressController.text.trim(),
        'bankname': _banknameController.text.trim(),
        'accountnumber': _accountnumberController.text.trim(),
        'ifsccode': _ifsccodeController.text.trim(),
        'PANno': _PANnoController.text.trim(),
        'UANno': _UANnoController.text.trim(),
        'ESIno': _ESInoController.text.trim(),
        'fathername': _fathernameController.text.trim(),
        'mobileAccessEnabled': _mobileAccessEnabled,
      };

      final id = widget.employee.id.isNotEmpty ? widget.employee.id : widget.employee.employeeId;
      final result = await employeeProvider.updateEmployee(id, employeeData);

      if (!mounted) return;
      if (result['success'] != false) {
        SnackbarUtils.showSuccess(context, 'Employee updated successfully');
        widget.onEmployeeUpdated();
        Navigator.pop(context);
      } else {
        SnackbarUtils.showError(
          context,
          result['message'] ?? 'Error updating employee',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Error: $e');
      }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Employee',
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
              onPressed: _updateEmployee,
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
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, 'Personal Information'),
                    _buildCard(context, [
                      _buildRow(context, [
                        _buildTextField(
                          context,
                          controller: _firstNameController,
                          label: 'First Name',
                          hint: 'John',
                          mandatory: true,
                          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                        _buildTextField(
                          context,
                          controller: _lastNameController,
                          label: 'Last Name',
                          hint: 'Doe',
                          mandatory: true,
                          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                        ),
                      ]),
                      _buildTextField(
                        context,
                        controller: _emailController,
                        label: 'Email',
                        hint: 'john.doe@example.com',
                        keyboardType: TextInputType.emailAddress,
                        mandatory: true,
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                      ),
                      _buildTextField(
                        context,
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: '+91 9876543210',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        context,
                        controller: _fathernameController,
                        label: 'Father\'s Name',
                        hint: 'Richard Doe',
                      ),
                      _buildRow(context, [
                        _buildDropdown<String?>(
                          context: context,
                          label: 'Gender',
                          value: _selectedGender,
                          items: [
                            DropdownMenuItem(value: null, child: Text('Not Specified')),
                            DropdownMenuItem(value: 'Male', child: Text('Male')),
                            DropdownMenuItem(value: 'Female', child: Text('Female')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                        _buildDatePicker(
                          context,
                          label: 'Date of Birth',
                          value: _dateOfBirth,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dateOfBirth,
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _dateOfBirth = picked);
                          },
                        ),
                      ]),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader(context, 'Professional Information'),
                    _buildCard(context, [
                      _buildReadOnlyField(context, 'Employee ID', widget.employee.employeeId),
                      _buildRow(context, [
                        _buildTextField(
                          context,
                          controller: _departmentController,
                          label: 'Department',
                          hint: 'Engineering',
                        ),
                        _buildTextField(
                          context,
                          controller: _designationController,
                          label: 'Designation',
                          hint: 'Software Engineer',
                        ),
                      ]),
                      _buildRow(context, [
                        _buildDropdown<String>(
                          context: context,
                          label: 'Role',
                          value: _selectedRole,
                          items: ['employee', 'admin', 'hr']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedRole = val!),
                        ),
                        _buildTextField(
                          context,
                          controller: _gradeController,
                          label: 'Grade',
                          hint: 'L2',
                        ),
                      ]),
                      _buildDatePicker(
                        context,
                        label: 'Joining Date',
                        value: _joiningDate,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _joiningDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _joiningDate = picked);
                        },
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader(context, 'Address'),
                    _buildCard(context, [
                      _buildTextField(
                        context,
                        controller: _addressController,
                        label: 'Full Address',
                        hint: '123, Main Street, City',
                        maxLines: 3,
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader(context, 'Bank Details'),
                    _buildCard(context, [
                      _buildTextField(
                        context,
                        controller: _banknameController,
                        label: 'Bank Name',
                        hint: 'HDFC Bank',
                      ),
                      _buildTextField(
                        context,
                        controller: _accountnumberController,
                        label: 'Account Number',
                        hint: '501002345678',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        context,
                        controller: _ifsccodeController,
                        label: 'IFSC Code',
                        hint: 'HDFC0001234',
                      ),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader(context, 'Government IDs'),
                    _buildCard(context, [
                      _buildTextField(
                        context,
                        controller: _PANnoController,
                        label: 'PAN Number',
                        hint: 'ABCDE1234F',
                      ),
                      _buildRow(context, [
                        _buildTextField(
                          context,
                          controller: _UANnoController,
                          label: 'UAN Number',
                          hint: '100123456789',
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          context,
                          controller: _ESInoController,
                          label: 'ESI Number',
                          hint: '1234567890',
                          keyboardType: TextInputType.number,
                        ),
                      ]),
                    ]),
                    SizedBox(height: 24),
                    _buildSectionHeader(context, 'Settings'),
                    _buildCard(context, [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Enable Mobile Access',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Allow employee to log in via mobile app',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        value: _mobileAccessEnabled,
                        onChanged: (val) => setState(() => _mobileAccessEnabled = val),
                        secondary: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.phone_android, color: colorScheme.primary),
                        ),
                      ),
                    ]),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _updateEmployee,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Update Employee',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildCard(BuildContext context, List<Widget> children) {
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
        children: children.expand((w) => [w, SizedBox(height: 16)]).toList()..removeLast(),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool mandatory = false,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
              Text(' *', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.error),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurface),
          dropdownColor: colorScheme.surfaceContainerHighest,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('dd-MM-yyyy').format(value),
                    style: GoogleFonts.poppins(fontSize: 14, color: colorScheme.onSurface),
                  ),
                ),
                Icon(Icons.calendar_today, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((w) => [Expanded(child: w), SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}
