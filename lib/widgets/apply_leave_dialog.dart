import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

class ApplyLeaveDialog extends StatefulWidget {
  const ApplyLeaveDialog({Key? key}) : super(key: key);

  @override
  _ApplyLeaveDialogState createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _leaveType;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 1));
  String _reason = '';

  @override
  void initState() {
    super.initState();
    // Fetch leave types when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      provider.fetchLeaveTypes();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (isValid) {
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found. Please login again.')),
        );
        return;
      }

      final selectedType =
          _leaveType ??
          (leaveProvider.leaveTypes.isNotEmpty
              ? leaveProvider.leaveTypes.first
              : 'Annual');

      await leaveProvider.applyLeave(
        employeeId: user.employeeId,
        leaveType: selectedType,
        from: _startDate,
        to: _endDate,
        reason: _reason,
      );

      // If provider captured an error, show a friendly message
      if (leaveProvider.error != null) {
        final raw = leaveProvider.error!.toString();
        final msg = raw.startsWith('Exception: ')
            ? raw.substring('Exception: '.length)
            : raw;
        final lower = msg.toLowerCase();
        final showApi = lower.contains('already') || lower.contains('exists');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              showApi ? msg : 'Could not apply leave. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Leave applied successfully')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveProvider>(context);
    List<String> allowedTypes = leaveProvider.leaveTypes.where((t) {
      final v = t.toLowerCase();
      return v == 'sick leave' ||
          v == 'personal leave' ||
          v == 'sick' ||
          v == 'personal';
    }).toList();
    if (allowedTypes.isEmpty) {
      allowedTypes = const ['Sick Leave', 'Personal Leave'];
    }
    final currentValue =
        (_leaveType != null && allowedTypes.contains(_leaveType))
        ? _leaveType
        : null;
    return AlertDialog(
      title: Text('Apply for Leave', style: AppTextStyles.heading),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: currentValue,
                items: allowedTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _leaveType = value;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Leave Type'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start Date: ${DateFormat.yMd().format(_startDate)}',
                      style: AppTextStyles.body,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text('Select'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'End Date: ${DateFormat.yMd().format(_endDate)}',
                      style: AppTextStyles.body,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text('Select'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Reason'),
                onChanged: (value) {
                  _reason = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: leaveProvider.isLoading ? null : _submitForm,
          child: leaveProvider.isLoading
              ? CircularProgressIndicator()
              : Text('Submit'),
        ),
      ],
    );
  }
}
