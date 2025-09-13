import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

class AdminLeaveRequestsScreen extends StatefulWidget {
  @override
  _AdminLeaveRequestsScreenState createState() => _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState extends State<AdminLeaveRequestsScreen> {
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).getAllLeaves();
    });
  }

  void _refreshLeaveRequests() {
    Provider.of<LeaveProvider>(context, listen: false).getAllLeaves();
  }

  List<Leave> _filterLeaveRequests(List<Leave> leaves) {
    if (_selectedStatus == 'all') return leaves;
    return leaves.where((leave) => leave.status.toLowerCase() == _selectedStatus).toList();
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Leave Requests',
                          style: AppTextStyles.subheading.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshLeaveRequests,
                        icon: Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Filter dropdown
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStatus,
                        hint: Text('Filter by status'),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Requests')),
                          DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          DropdownMenuItem(value: 'approved', child: Text('Approved')),
                          DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
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
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
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
                  child: _buildLeaveRequestsList(filteredLeaves),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestsList(List<Leave> leaves) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return _buildLeaveRequestCard(leave);
      },
    );
  }

  Widget _buildLeaveRequestCard(Leave leave) {
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
                   radius: 20,
                   backgroundColor: Color(0xFF1976D2),
                   child: Text(
                     leave.employeeName.isNotEmpty
                         ? leave.employeeName.substring(0, 1).toUpperCase()
                         : 'U',
                     style: TextStyle(
                       color: Colors.white,
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
                        leave.employeeName,
                        style: AppTextStyles.subheading.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Applied: ${DateFormat.yMMMd().format(leave.appliedDate)}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(leave.status),
              ],
            ),
            SizedBox(height: 16),
            
            // Leave Type and Duration
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.category,
                    label: 'Leave Type',
                    value: leave.leaveType,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: '${leave.totalDays} day${leave.totalDays > 1 ? 's' : ''}',
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
                    icon: Icons.date_range,
                    label: 'From Date',
                    value: DateFormat.yMMMd().format(leave.fromDate),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.date_range,
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
                icon: Icons.comment,
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
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Admin Action',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      leave.action,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Action Buttons (only for pending requests)
            if (leave.status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showStatusUpdateDialog(leave),
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('Update Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF1976D2),
                        side: BorderSide(color: Color(0xFF1976D2)),
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
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 6),
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
      ),
    );
  }

  Future<void> _quickApprove(Leave leave) async {
    try {
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
      await leaveProvider.updateLeaveStatus(leave.id, 'approved');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Leave request approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshLeaveRequests();
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

  StatusUpdateDialog({required this.leave, required this.onStatusUpdated});

  @override
  _StatusUpdateDialogState createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  final _commentsController = TextEditingController();
  
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.leave.status;
    _commentsController.text = widget.leave.action;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Leave Status'),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.leave.employeeName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${widget.leave.leaveType} - ${DateFormat.yMMMd().format(widget.leave.fromDate)} to ${DateFormat.yMMMd().format(widget.leave.toDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Duration: ${widget.leave.totalDays} day${widget.leave.totalDays > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Status Dropdown
            Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            SizedBox(height: 16),

            // Comments
            Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _commentsController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add admin comments (optional)',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                 ElevatedButton(
           onPressed: _updateStatus,
           child: Text('Update'),
         ),
      ],
    );
  }

  Future<void> _updateStatus() async {
    try {
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
      await leaveProvider.updateLeaveStatus(
        widget.leave.id,
        _selectedStatus,
      );

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
