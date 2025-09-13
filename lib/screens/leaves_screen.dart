import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/widgets/apply_leave_dialog.dart';
import 'package:quantum_dashboard/widgets/leave_accordion.dart';
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user != null) {
        Provider.of<LeaveProvider>(context, listen: false).getMyLeaves(user.employeeId);
      }
    });
  }

  void _applyForLeave() {
    showDialog(context: context, builder: (context) => ApplyLeaveDialog());
  }

  void _editLeave(Leave leave) {
    // TODO: Implement edit leave functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit leave: ${leave.type}'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteLeave(Leave leave) {
    // TODO: Implement delete leave functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Leave'),
        content: Text('Are you sure you want to delete this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Leave deleted: ${leave.type}'),
                  duration: Duration(seconds: 2),
                ),
              );
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
