import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/services/department_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';
import 'package:quantum_dashboard/utils/string_extensions.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedRecipientType = 'single';
  String? _selectedEmployeeId;
  String? _selectedDepartment;
  String _selectedType = 'general';
  bool _isLoading = false;

  List<String> _departments = [];
  bool _loadingDepartments = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadEmployees();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDepartments = true);
    try {
      final departmentService = DepartmentService();
      final depts = await departmentService.getDepartments();
      setState(() {
        _departments = depts.map((d) => d.department).toSet().toList();
      });
    } catch (e) {
      print('Error loading departments: $e');
    } finally {
      setState(() => _loadingDepartments = false);
    }
  }

  Future<void> _loadEmployees() async {
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );
    if (employeeProvider.employees.isEmpty) {
      await employeeProvider.getAllEmployees();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRecipientType == 'single' && _selectedEmployeeId == null) {
      SnackbarUtils.showError(context, 'Please select an employee');
      return;
    }

    if (_selectedRecipientType == 'department' && _selectedDepartment == null) {
      SnackbarUtils.showError(context, 'Please select a department');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );

      final senderId = authProvider.user?.employeeId ?? '';
      final senderName = authProvider.user?.fullName ?? 'Admin';

      List<String> recipientIds = [];

      if (_selectedRecipientType == 'single') {
        recipientIds = [_selectedEmployeeId!];
      } else if (_selectedRecipientType == 'all') {
        recipientIds =
            employeeProvider.employees.map((e) => e.employeeId).toList();
      } else if (_selectedRecipientType == 'department') {
        recipientIds = employeeProvider.employees
            .where((e) => e.department == _selectedDepartment)
            .map((e) => e.employeeId)
            .toList();
      }

      if (recipientIds.isEmpty) {
        SnackbarUtils.showError(context, 'No recipients found');
        setState(() => _isLoading = false);
        return;
      }

      int successCount = 0;
      for (final recipientId in recipientIds) {
        try {
          await notificationProvider.createNotification(
            recipientId: recipientId,
            senderId: senderId,
            senderName: senderName,
            type: _selectedType,
            title: _titleController.text.trim(),
            message: _messageController.text.trim(),
          );
          successCount++;
        } catch (e) {
          print('Error sending notification to $recipientId: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showSuccess(
          context,
          'Notification sent to $successCount recipient(s)',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to send notification: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Notification'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedRecipientType,
                        decoration: InputDecoration(
                          labelText: 'Send To',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'single',
                            child: Text('Single Employee'),
                          ),
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Employees'),
                          ),
                          DropdownMenuItem(
                            value: 'department',
                            child: Text('Department'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRecipientType = value!;
                            _selectedEmployeeId = null;
                            _selectedDepartment = null;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      if (_selectedRecipientType == 'single')
                        Consumer<EmployeeProvider>(
                          builder: (context, provider, child) {
                            return DropdownButtonFormField<String>(
                              value: _selectedEmployeeId,
                              decoration: InputDecoration(
                                labelText: 'Employee',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: provider.employees.map((emp) {
                                return DropdownMenuItem(
                                  value: emp.employeeId,
                                  child: Text(emp.fullName.toTitleCase()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedEmployeeId = value);
                              },
                            );
                          },
                        ),
                      if (_selectedRecipientType == 'department')
                        _loadingDepartments
                            ? CircularProgressIndicator()
                            : DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                decoration: InputDecoration(
                                  labelText: 'Department',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _departments.map((dept) {
                                  return DropdownMenuItem(
                                    value: dept,
                                    child: Text(dept),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedDepartment = value);
                                },
                              ),
                      if (_selectedRecipientType == 'department' ||
                          _selectedRecipientType == 'single')
                        SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'general',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(
                            value: 'system',
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: 'leave',
                            child: Text('Leave'),
                          ),
                          DropdownMenuItem(
                            value: 'payslip',
                            child: Text('Payslip'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 4,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
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
                      onPressed: _isLoading ? null : _sendNotification,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Send'),
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
      ),
    );
  }
}
