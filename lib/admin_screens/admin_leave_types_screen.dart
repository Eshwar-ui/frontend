import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/services/leave_type_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminLeaveTypesScreen extends StatefulWidget {
  const AdminLeaveTypesScreen({super.key});

  @override
  State<AdminLeaveTypesScreen> createState() => _AdminLeaveTypesScreenState();
}

class _AdminLeaveTypesScreenState extends State<AdminLeaveTypesScreen> {
  final LeaveTypeService _leaveTypeService = LeaveTypeService();
  List<LeaveType> _leaveTypes = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaveTypes();
  }

  Future<void> _loadLeaveTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leaveTypes = await _leaveTypeService.getLeaveTypes();
      setState(() {
        _leaveTypes = leaveTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addLeaveType() async {
    final leaveTypeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Leave Type'),
        content: TextField(
          controller: leaveTypeController,
          decoration: InputDecoration(
            labelText: 'Leave Type',
            hintText: 'e.g., Sick Leave',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (leaveTypeController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _leaveTypeService.addLeaveType(
          leaveType: leaveTypeController.text.trim(),
        );
        _loadLeaveTypes();
        SnackbarUtils.showSuccess(context, 'Leave type added successfully!');
      } catch (e) {
        SnackbarUtils.showError(
          context,
          'Failed to add leave type: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _editLeaveType(LeaveType leaveType) async {
    final leaveTypeController = TextEditingController(
      text: leaveType.leaveType,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Leave Type'),
        content: TextField(
          controller: leaveTypeController,
          decoration: InputDecoration(
            labelText: 'Leave Type',
            hintText: 'e.g., Sick Leave',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (leaveTypeController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _leaveTypeService.updateLeaveType(
          id: leaveType.id,
          leaveType: leaveTypeController.text.trim(),
        );
        _loadLeaveTypes();
        SnackbarUtils.showSuccess(context, 'Leave type updated successfully!');
      } catch (e) {
        SnackbarUtils.showError(
          context,
          'Failed to update leave type: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteLeaveType(LeaveType leaveType) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Leave Type'),
        content: Text(
          'Are you sure you want to delete ${leaveType.leaveType}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _leaveTypeService.deleteLeaveType(leaveType.id);
        _loadLeaveTypes();
        SnackbarUtils.showSuccess(context, 'Leave type deleted successfully!');
      } catch (e) {
        SnackbarUtils.showError(
          context,
          'Failed to delete leave type: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);

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
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Leave Types',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<NavigationProvider>(
              context,
              listen: false,
            ).setCurrentPage(NavigationPage.Dashboard);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addLeaveType,
            tooltip: 'Add Leave Type',
          ),
        ],
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading leave types',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadLeaveTypes,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _leaveTypes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No leave types found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a new leave type to get started',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: 120, // Extra padding for nav bar
                    ),
                    itemCount: _leaveTypes.length,
                    itemBuilder: (context, index) {
                      final leaveType = _leaveTypes[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            child: Icon(
                              Icons.event_busy,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            leaveType.leaveType,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                color: colorScheme.primary,
                                onPressed: () => _editLeaveType(leaveType),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20),
                                color: colorScheme.error,
                                onPressed: () => _deleteLeaveType(leaveType),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
