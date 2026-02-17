import 'package:flutter/material.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

class AdminLeaveRequestsScreen extends StatefulWidget {
  @override
  _AdminLeaveRequestsScreenState createState() =>
      _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState extends State<AdminLeaveRequestsScreen> {
  String _selectedStatus = 'all';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).getAllLeaves();
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
    });
  }

  void _refreshLeaveRequests() {
    Provider.of<LeaveProvider>(context, listen: false).getAllLeaves();
  }

  List<Leave> _filterLeaveRequests(List<Leave> leaves) {
    var filtered = leaves;

    // Status filter
    if (_selectedStatus != 'all') {
      filtered = filtered.where((leave) {
        final status = leave.status.toLowerCase().trim();
        switch (_selectedStatus) {
          case 'new':
            return status == 'new';
          case 'pending':
            return status == 'pending' || status.contains('pend');
          case 'approved':
            return status == 'approved' || status.contains('approv');
          case 'rejected':
            return status == 'rejected' ||
                status == 'declined' ||
                status.contains('reject');
          default:
            return status == _selectedStatus;
        }
      }).toList();
    }

    // Date filter (leave period overlaps with selected range)
    if (_dateFrom != null || _dateTo != null) {
      final from = _dateFrom ?? DateTime(2000);
      final to = _dateTo ?? DateTime(2100);
      final rangeStart = DateTime(from.year, from.month, from.day);
      final rangeEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);

      filtered = filtered.where((leave) {
        final leaveStart = DateTime(leave.from.year, leave.from.month, leave.from.day);
        final leaveEnd = DateTime(leave.to.year, leave.to.month, leave.to.day, 23, 59, 59);
        return !leaveStart.isAfter(rangeEnd) && !leaveEnd.isBefore(rangeStart);
      }).toList();
    }

    return filtered;
  }

  String _getEmployeeName(Leave leave) {
    // Try to find in EmployeeProvider for the most up-to-date name
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );
    final employee = employeeProvider.employees.firstWhere(
      (e) => e.employeeId == leave.employeeId || e.id == leave.employeeId,
      orElse: () => Employee(
        id: '',
        employeeId: '',
        firstName: '',
        lastName: '',
        email: '',
        mobile: '',
        dateOfBirth: DateTime.now(),
        joiningDate: DateTime.now(),
        password: '',
        profileImage: '',
      ),
    );

    if (employee.firstName.isNotEmpty || employee.lastName.isNotEmpty) {
      return '${employee.fullName} (${leave.employeeId})';
    }

    // Fallback 1: If leave already has employee object with name
    if (leave.employee != null && leave.employee!.fullName.trim().isNotEmpty) {
      return '${leave.employee!.fullName} (${leave.employeeId})';
    }

    // Fallback 2: use what's in leave.employeeName (likely "Employee ID: xyz")
    return leave.employeeName;
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
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leave Requests',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Manage employee leaves',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _refreshLeaveRequests,
                    icon: Icon(Icons.refresh, color: colorScheme.primary),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Filters row
              Row(
                children: [
                  // Status filter
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedStatus,
                          dropdownColor: colorScheme.surfaceContainerHighest,
                          hint: Text('Filter by status'),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('All Requests'),
                            ),
                            DropdownMenuItem(
                              value: 'new',
                              child: Text('New'),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'approved',
                              child: Text('Approved'),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text('Rejected'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Date filter - From
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateFrom ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateFrom = picked;
                            if (_dateTo != null && _dateTo!.isBefore(picked)) {
                              _dateTo = picked;
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 18, color: colorScheme.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dateFrom != null
                                    ? DateFormat('dd/MM/yy').format(_dateFrom!)
                                    : 'From',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _dateFrom != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Date filter - To
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateTo ?? _dateFrom ?? DateTime.now(),
                          firstDate: _dateFrom ?? DateTime(2020),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _dateTo = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 18, color: colorScheme.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dateTo != null
                                    ? DateFormat('dd/MM/yy').format(_dateTo!)
                                    : 'To',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _dateTo != null
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(0.6),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_dateFrom != null || _dateTo != null) ...[
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _dateFrom = null;
                          _dateTo = null;
                        });
                      },
                      icon: Icon(Icons.clear, color: colorScheme.primary),
                      tooltip: 'Clear date filter',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Leave Requests List
        Expanded(
          child: Consumer<LeaveProvider>(
            builder: (context, leaveProvider, child) {
              if (leaveProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (leaveProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading leave requests',
                        style: AppTextStyles.subheading,
                      ),
                      SizedBox(height: 8),
                      Text(
                        leaveProvider.error!,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshLeaveRequests,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (leaveProvider.leaves.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No Leave Requests',
                        style: AppTextStyles.subheading,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No leave requests found.',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                );
              }

              final filteredLeaves = _filterLeaveRequests(leaveProvider.leaves);

              if (filteredLeaves.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_list_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No ${_selectedStatus == 'all' ? '' : _selectedStatus} requests found',
                        style: AppTextStyles.subheading,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshLeaveRequests(),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
                  itemCount: filteredLeaves.length,
                  itemBuilder: (context, index) {
                    final leave = filteredLeaves[index];
                    return _buildLeaveRequestCard(leave);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveRequestCard(Leave leave) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.15 : 0.08,
            ),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    _getEmployeeName(leave).isNotEmpty
                        ? _getEmployeeName(leave).substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getEmployeeName(leave),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Applied: ${DateFormat.yMMMd().format(leave.appliedDate)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(leave.status),
              ],
            ),
            SizedBox(height: 16),
            Divider(color: colorScheme.outline.withOpacity(0.1)),
            SizedBox(height: 16),

            // Leave Type and Duration
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.category_outlined,
                    label: 'Leave Type',
                    value: leave.leaveType,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule_outlined,
                    label: 'Duration',
                    value:
                        '${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Leave Dates
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'From Date',
                    value: DateFormat.yMMMd().format(leave.fromDate),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.event_available_outlined,
                    label: 'To Date',
                    value: DateFormat.yMMMd().format(leave.toDate),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Reason
            if (leave.reason.isNotEmpty) ...[
              _buildInfoItem(
                icon: Icons.comment_outlined,
                label: 'Reason',
                value: leave.reason,
              ),
              SizedBox(height: 16),
            ],

            // Admin Action (if any)
            if (leave.action.isNotEmpty && leave.action != '-') ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Admin Action',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      leave.action,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Action Buttons (only for new or pending requests)
            if (leave.status.toLowerCase() == 'new' ||
                leave.status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(leave),
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('Update Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _quickApprove(leave),
                      icon: Icon(Icons.check, size: 16),
                      label: Text('Quick Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Center(
                child: TextButton.icon(
                  onPressed: () => _showStatusUpdateDialog(leave),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Update Status'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'approved':
        chipColor = Colors.green;
        break;
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'rejected':
        chipColor = Colors.red;
        break;
      case 'new':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: chipColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStatusUpdateDialog(Leave leave) {
    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(
        leave: leave,
        onStatusUpdated: _refreshLeaveRequests,
        employeeName: _getEmployeeName(leave),
      ),
    );
  }

  Future<void> _quickApprove(Leave leave) async {
    try {
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
      // Backend expects 'Approved' (capitalized)
      await leaveProvider.updateLeaveStatus(leave.id, 'Approved');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave request approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshLeaveRequests();

      // Notification is created automatically by backend
      // Refresh notification count if provider is available
      try {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        await notificationProvider.loadUnreadCount();
      } catch (e) {
        // Notification provider might not be available, ignore
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving leave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Status Update Dialog
class StatusUpdateDialog extends StatefulWidget {
  final Leave leave;
  final VoidCallback onStatusUpdated;
  final String employeeName;

  StatusUpdateDialog({
    required this.leave,
    required this.onStatusUpdated,
    required this.employeeName,
  });

  @override
  _StatusUpdateDialogState createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  final _commentsController = TextEditingController();
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    // Normalize the status to match dropdown items
    final currentStatus = widget.leave.status.toLowerCase().trim();
    if (currentStatus == 'declined' ||
        currentStatus == 'reject' ||
        currentStatus.contains('reject')) {
      _selectedStatus = 'rejected';
    } else if (currentStatus == 'approve' || currentStatus.contains('approv')) {
      _selectedStatus = 'approved';
    } else if (currentStatus == 'pending' || currentStatus.contains('pend')) {
      _selectedStatus = 'pending';
    } else if (currentStatus == 'new') {
      _selectedStatus = 'new';
    } else {
      _selectedStatus = 'pending';
    }
    _commentsController.text = widget.leave.action;
  }

  @override
  Widget build(BuildContext context) {
    // Reusing similar logic but updating UI for dialog if needed, keeping it standard for now but with rounded corners
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Update Leave Status',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.employeeName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.leave.leaveType}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: ['new', 'pending', 'approved', 'rejected']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _commentsController,
              decoration: InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Add admin comments',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(onPressed: _updateStatus, child: Text('Update')),
      ],
    );
  }

  Future<void> _updateStatus() async {
    try {
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);

      // Map frontend status to backend expected format (New, Approved, Rejected)
      String backendStatus;
      switch (_selectedStatus.toLowerCase()) {
        case 'approved':
          backendStatus = 'Approved';
          break;
        case 'rejected':
          backendStatus = 'Rejected';
          break;
        case 'new':
        case 'pending':
          backendStatus = 'New';
          break;
        default:
          backendStatus = 'New';
      }

      await leaveProvider.updateLeaveStatus(widget.leave.id, backendStatus);
      Navigator.pop(context);
      widget.onStatusUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating leave status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}
