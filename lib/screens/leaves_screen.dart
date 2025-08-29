import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/widgets/apply_leave_dialog.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/models/leave_model.dart';

class LeavesScreen extends StatefulWidget {
  @override
  _LeavesScreenState createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).getMyLeaves();
    });
  }

  void _applyForLeave() {
    showDialog(context: context, builder: (context) => ApplyLeaveDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leaves', style: AppTextStyles.heading)),
      body: Consumer<LeaveProvider>(
        builder: (context, leaveProvider, child) {
          if (leaveProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (leaveProvider.error != null) {
            return Center(child: Text('Error: ${leaveProvider.error}'));
          } else if (leaveProvider.leaves.isEmpty) {
            return Center(
              child: Text('No leaves found.', style: AppTextStyles.body),
            );
          }

          final leaves = leaveProvider.leaves;
          return ListView.builder(
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(leave.leaveType, style: AppTextStyles.subheading),
                  subtitle: Text(
                    '${DateFormat.yMd().format(leave.startDate)} - ${DateFormat.yMd().format(leave.endDate)}',
                    style: AppTextStyles.body,
                  ),
                  trailing: Text(
                    leave.status,
                    style: AppTextStyles.body.copyWith(
                      color: _getStatusColor(leave.status),
                    ),
                  ),
                ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
