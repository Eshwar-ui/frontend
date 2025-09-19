import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/widgets/apply_leave_dialog.dart';
import 'package:quantum_dashboard/widgets/leave_accordion.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:intl/intl.dart';

class LeavesScreen extends StatefulWidget {
  @override
  _LeavesScreenState createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  String? _lastErrorMessage;
  // Store references to providers to avoid deactivated widget errors
  AuthProvider? _authProvider;
  LeaveProvider? _leaveProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _authProvider != null && _leaveProvider != null) {
        final user = _authProvider!.user;
        if (user != null) {
          _leaveProvider!.getMyLeaves(user.employeeId);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save references to providers to avoid deactivated widget errors
    try {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    } catch (e) {
      // Handle case where context is no longer valid
      print('Error accessing providers in didChangeDependencies: $e');
    }
  }

  void _applyForLeave() {
    showDialog(context: context, builder: (context) => ApplyLeaveDialog());
  }

  void _editLeave(Leave leave) {
    // Check if leave can be edited (only pending or new leaves)
    if (leave.status.toLowerCase() != 'pending' &&
        leave.status.toLowerCase() != 'new') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only pending or new leave requests can be edited.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) =>
          _EditLeaveDialog(parentContext: parentContext, leave: leave),
    );
  }

  void _deleteLeave(Leave leave) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete Leave'),
        content: Text(
          'Are you sure you want to delete this leave request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog using its own context
              Navigator.of(dialogContext).pop();

              // Show loading indicator
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Deleting leave request...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              try {
                if (!mounted) return;

                // Use stored provider references instead of accessing context
                if (_authProvider == null || _leaveProvider == null) {
                  throw Exception('Providers not available');
                }

                final user = _authProvider!.user;

                if (user != null) {
                  await _leaveProvider!.deleteLeave(user.employeeId, leave.id);

                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('Leave request deleted successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  throw Exception('User not found');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not delete leave. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          'Leaves',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, leaveProvider, child) {
          // Show error as a snackbar without blocking the whole screen
          if (leaveProvider.error != null &&
              leaveProvider.error != _lastErrorMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _lastErrorMessage = leaveProvider.error;
              final raw = leaveProvider.error!.toString();
              final msg = raw.startsWith('Exception: ')
                  ? raw.substring('Exception: '.length)
                  : raw;
              final lower = msg.toLowerCase();
              final showApi =
                  lower.contains('already') || lower.contains('exists');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    showApi ? msg : 'Something went wrong. Please try again.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
            });
          }

          // Only block the screen on initial load when there is no data yet
          if (leaveProvider.isLoading && leaveProvider.leaves.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } else if (leaveProvider.leaves.isEmpty) {
            return Center(
              child: Text('No leaves found.', style: AppTextStyles.body),
            );
          }

          final leaves = leaveProvider.leaves;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return LeaveAccordion(
                leave: leave,
                onEdit: () => _editLeave(leave),
                onDelete: () => _deleteLeave(leave),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _applyForLeave,
        child: Icon(Icons.add),
      ),
    );
  }
}

class _EditLeaveDialog extends StatefulWidget {
  final Leave leave;
  final BuildContext parentContext;

  const _EditLeaveDialog({required this.parentContext, required this.leave});

  @override
  _EditLeaveDialogState createState() => _EditLeaveDialogState();
}

class _EditLeaveDialogState extends State<_EditLeaveDialog> {
  late TextEditingController _reasonController;
  late DateTime _fromDate;
  late DateTime _toDate;
  late String _selectedLeaveType;
  bool _isLoading = false;

  // Store references to providers to avoid deactivated widget errors
  AuthProvider? _authProvider;
  LeaveProvider? _leaveProvider;

  List<String> _leaveTypes = [];

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.leave.reason);
    _fromDate = widget.leave.fromDate;
    _toDate = widget.leave.toDate;

    // Fetch leave types from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provider = Provider.of<LeaveProvider>(context, listen: false);
        await provider.fetchLeaveTypes();
        if (!mounted) return;
        setState(() {
          // Allow only Sick Leave and Personal Leave
          _leaveTypes = provider.leaveTypes.where((t) {
            final v = t.toLowerCase();
            return v == 'sick leave' ||
                v == 'personal leave' ||
                v == 'sick' ||
                v == 'personal';
          }).toList();
          if (_leaveTypes.isEmpty) {
            _leaveTypes = ['Sick Leave', 'Personal Leave'];
          }
        });
      } catch (_) {}
    });

    // Handle potential mismatch between stored type and dropdown values
    final storedType = widget.leave.type;
    print('Stored leave type: "$storedType"');
    print('Available types: $_leaveTypes');

    // Check if the stored type exists in our dropdown list
    if (_leaveTypes.contains(storedType)) {
      _selectedLeaveType = storedType;
    } else {
      // If not found, try to find a close match or default to first item
      if (storedType.toLowerCase().contains('annual')) {
        _selectedLeaveType = 'Annual Leave';
      } else if (storedType.toLowerCase().contains('sick')) {
        _selectedLeaveType = 'Sick Leave';
      } else if (storedType.toLowerCase().contains('personal')) {
        _selectedLeaveType = 'Personal Leave';
      } else if (storedType.toLowerCase().contains('maternity')) {
        _selectedLeaveType = 'Maternity Leave';
      } else if (storedType.toLowerCase().contains('paternity')) {
        _selectedLeaveType = 'Paternity Leave';
      } else if (storedType.toLowerCase().contains('emergency')) {
        _selectedLeaveType = 'Emergency Leave';
      } else if (storedType.toLowerCase().contains('study')) {
        _selectedLeaveType = 'Study Leave';
      } else {
        _selectedLeaveType = _leaveTypes.first; // Default to first item
      }
      print('Mapped "$storedType" to "$_selectedLeaveType"');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save references to providers to avoid deactivated widget errors
    try {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
    } catch (e) {
      // Handle case where context is no longer valid
      print('Error accessing providers in didChangeDependencies: $e');
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate;
          }
        } else {
          _toDate = picked;
          if (_fromDate.isAfter(_toDate)) {
            _fromDate = _toDate;
          }
        }
      });
    }
  }

  Future<void> _updateLeave() async {
    if (!mounted) return;

    if (_reasonController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a reason for the leave.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_fromDate.isAfter(_toDate)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('From date cannot be after to date.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      if (!mounted) return;

      // Use stored provider references instead of accessing context
      if (_authProvider == null || _leaveProvider == null) {
        throw Exception('Providers not available');
      }

      final user = _authProvider!.user;

      if (user != null) {
        final leaveData = {
          'leaveType': _selectedLeaveType,
          'from': _fromDate.toIso8601String(),
          'to': _toDate.toIso8601String(),
          'reason': _reasonController.text.trim(),
          'days': _toDate.difference(_fromDate).inDays + 1,
        };

        await _leaveProvider!.updateLeave(
          user.employeeId,
          widget.leave.id,
          leaveData,
        );

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(widget.parentContext).showSnackBar(
            SnackBar(
              content: Text('Leave updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Could not update leave. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Leave Request'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Type Dropdown
            Text('Leave Type', style: AppTextStyles.subheading),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _leaveTypes.contains(_selectedLeaveType)
                  ? _selectedLeaveType
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _leaveTypes.map((String type) {
                return DropdownMenuItem<String>(value: type, child: Text(type));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLeaveType = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 16),

            // From Date
            Text('From Date', style: AppTextStyles.subheading),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text(DateFormat.yMMMd().format(_fromDate)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // To Date
            Text('To Date', style: AppTextStyles.subheading),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 8),
                    Text(DateFormat.yMMMd().format(_toDate)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Reason
            Text('Reason', style: AppTextStyles.subheading),
            SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter reason for leave...',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Duration: ${_toDate.difference(_fromDate).inDays + 1} day${_toDate.difference(_fromDate).inDays + 1 != 1 ? 's' : ''}',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateLeave,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Update'),
        ),
      ],
    );
  }
}
