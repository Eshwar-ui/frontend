import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/compoff_provider.dart';
import 'package:quantum_dashboard/utils/responsive_utils.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({Key? key}) : super(key: key);

  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _leaveType;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 1));
  String _reason = '';
  String? _selectedCompoffCreditId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      provider.fetchLeaveTypes();
      Provider.of<CompoffProvider>(
        context,
        listen: false,
      ).fetchMyCredits(status: 'AVAILABLE');
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
          if ((_leaveType ?? '').toUpperCase() == 'COMPOFF') {
            _endDate = picked;
          }
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

      if (selectedType.toUpperCase() == 'COMPOFF' &&
          (_selectedCompoffCreditId == null ||
              _selectedCompoffCreditId!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a compoff credit.')),
        );
        return;
      }

      await leaveProvider.applyLeave(
        employeeId: user.employeeId,
        leaveType: selectedType,
        from: _startDate,
        to: _endDate,
        reason: _reason,
        compoffCreditId: selectedType.toUpperCase() == 'COMPOFF'
            ? _selectedCompoffCreditId
            : null,
      );

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leaveProvider = Provider.of<LeaveProvider>(context);
    final compoffProvider = Provider.of<CompoffProvider>(context);
    final availableCredits = compoffProvider.credits
        .where((c) => c.status == 'AVAILABLE')
        .toList();

    List<String> allowedTypes = leaveProvider.leaveTypes.where((t) {
      final v = t.toLowerCase();
      return v == 'sick leave' ||
          v == 'personal leave' ||
          v == 'sick' ||
          v == 'personal';
    }).toList();
    if (allowedTypes.isEmpty) {
      allowedTypes = const ['Sick Leave', 'Personal Leave', 'COMPOFF'];
    } else if (!allowedTypes.any((t) => t.toUpperCase() == 'COMPOFF')) {
      allowedTypes.add('COMPOFF');
    }
    final currentValue =
        (_leaveType != null && allowedTypes.contains(_leaveType))
        ? _leaveType
        : null;
    final isCompoff = (currentValue ?? '').toUpperCase() == 'COMPOFF';

    final inputDecoration = InputDecoration(
      labelText: 'Leave Type',
      fillColor: colorScheme.surfaceContainerHighest,
      filled: true,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Apply for Leave',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.padding(context),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: currentValue,
                isExpanded: true,
                dropdownColor: colorScheme.surfaceContainerHighest,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text(
                      'Select Leave Type',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ...allowedTypes.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _leaveType = value;
                      _selectedCompoffCreditId = null;
                      if (value.toUpperCase() == 'COMPOFF') {
                        _endDate = _startDate;
                      }
                    });
                  }
                },
                decoration: inputDecoration.copyWith(
                  hintText: 'Select Leave Type',
                ),
              ),
              if (isCompoff) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                DropdownButtonFormField<String>(
                  value: _selectedCompoffCreditId,
                  isExpanded: true,
                  dropdownColor: colorScheme.surfaceContainerHighest,
                  items: availableCredits
                      .map(
                        (credit) => DropdownMenuItem(
                          value: credit.id,
                          child: Text(
                            '${DateFormat('dd MMM').format(credit.earnedDate)} → Expires ${DateFormat('dd MMM').format(credit.expiryDate)}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCompoffCreditId = value;
                    });
                  },
                  decoration: inputDecoration.copyWith(
                    labelText: 'Select Compoff Credit',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a compoff credit';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start Date: ${DateFormat.yMd().format(_startDate)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      'Select',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'End Date: ${DateFormat.yMd().format(_endDate)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: isCompoff
                        ? null
                        : () => _selectDate(context, false),
                    child: Text(
                      'Select',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
              TextFormField(
                maxLines: 5,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: inputDecoration.copyWith(
                  // hintMaxLines: 5,
                  labelText: 'Reason',
                  alignLabelWithHint: true
                ),
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
              SizedBox(height: ResponsiveUtils.spacing(context, base: 24)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, base: 12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: leaveProvider.isLoading ? null : _submitForm,
                      child: leaveProvider.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Submit'),
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
