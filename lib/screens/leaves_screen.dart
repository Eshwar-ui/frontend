import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/screens/apply_leave_screen.dart';
import 'package:quantum_dashboard/widgets/leave_accordion.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/utils/error_handler.dart';
import 'package:quantum_dashboard/widgets/error_widget.dart';
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save references to providers to avoid deactivated widget errors
    try {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _leaveProvider = Provider.of<LeaveProvider>(context, listen: false);

      // Load leaves data after providers are available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _authProvider != null && _leaveProvider != null) {
          final user = _authProvider!.user;
          if (user != null) {
            _leaveProvider!.getMyLeaves(user.employeeId);
          }
        }
      });
    } catch (e) {
      // Handle case where context is no longer valid
      print('Error accessing providers in didChangeDependencies: $e');
    }
  }

  void _applyForLeave() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ApplyLeaveScreen()),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Leave',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this leave request? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
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
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Leaves',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyForLeave,
        icon: const Icon(Icons.add),
        label: const Text('Apply'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            // Container(
            //   padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            //   child: Row(
            //     children: [
            //       Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             'My Leaves',
            //             style: GoogleFonts.poppins(
            //               fontSize: 28,
            //               fontWeight: FontWeight.bold,
            //               color: colorScheme.onSurface,
            //             ),
            //           ),
            //           Text(
            //             'View and manage your leave requests',
            //             style: GoogleFonts.poppins(
            //               fontSize: 14,
            //               fontWeight: FontWeight.w400,
            //               color: colorScheme.onSurface.withOpacity(0.7),
            //             ),
            //           ),
            //         ],
            //       ),
            //       Spacer(),
            //       ElevatedButton.icon(
            //         onPressed: _applyForLeave,
            //         icon: Icon(Icons.add, size: 20),
            //         label: Text('Apply'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: colorScheme.primary,
            //           foregroundColor: colorScheme.onPrimary,
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(12),
            //           ),
            //           padding: EdgeInsets.symmetric(
            //             horizontal: 16,
            //             vertical: 12,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            SizedBox(height: 16),
            // Leaves List
            Expanded(
              child: Consumer<LeaveProvider>(
                builder: (context, leaveProvider, child) {
                  // Show error as a snackbar without blocking the whole screen
                  if (leaveProvider.error != null &&
                      leaveProvider.error != _lastErrorMessage) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _lastErrorMessage = leaveProvider.error;
                      ErrorHandler.showError(
                        context,
                        error: leaveProvider.error,
                        onRetry: () {
                          if (_authProvider?.user != null) {
                            _leaveProvider?.getMyLeaves(
                              _authProvider!.user!.employeeId,
                            );
                          }
                        },
                      );
                    });
                  }

                  // Show error state if there's an error and no data
                  if (leaveProvider.error != null &&
                      leaveProvider.leaves.isEmpty &&
                      !leaveProvider.isLoading) {
                    return ErrorStateWidget(
                      title: 'Unable to load leave requests',
                      message: ErrorHandler.getErrorMessage(
                        leaveProvider.error,
                      ),
                      onRetry: () {
                        if (_authProvider?.user != null) {
                          _leaveProvider?.getMyLeaves(
                            _authProvider!.user!.employeeId,
                          );
                        }
                      },
                    );
                  }

                  // Only block the screen on initial load when there is no data yet
                  if (leaveProvider.isLoading && leaveProvider.leaves.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  } else if (leaveProvider.leaves.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.event_busy,
                      title: 'No leave requests yet',
                      message:
                          'Your leave requests will appear here once you apply for leave.',
                      actionLabel: 'Apply for Leave',
                      onAction: _applyForLeave,
                    );
                  }

                  final leaves = leaveProvider.leaves;
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_authProvider?.user != null) {
                        await leaveProvider.getMyLeaves(
                          _authProvider!.user!.employeeId,
                        );
                      }
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        0,
                        24,
                        120,
                      ), // Bottom padding for nav bar
                      itemCount: leaves.length,
                      itemBuilder: (context, index) {
                        final leave = leaves[index];
                        return LeaveAccordion(
                          leave: leave,
                          onEdit: () => _editLeave(leave),
                          onDelete: () => _deleteLeave(leave),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Edit Leave Request',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Type Dropdown
            Text(
              'Leave Type',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _leaveTypes.contains(_selectedLeaveType)
                  ? _selectedLeaveType
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            Text(
              'From Date',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMd().format(_fromDate),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // To Date
            Text(
              'To Date',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMd().format(_toDate),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Reason
            Text(
              'Reason',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter reason for leave...',
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Duration: ${_toDate.difference(_fromDate).inDays + 1} day${_toDate.difference(_fromDate).inDays + 1 != 1 ? 's' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateLeave,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Update', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}
