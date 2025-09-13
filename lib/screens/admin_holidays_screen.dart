import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_loading_widget.dart';
import 'package:quantum_dashboard/widgets/add_holiday_dialog.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminHolidaysScreen extends StatefulWidget {
  @override
  _AdminHolidaysScreenState createState() => _AdminHolidaysScreenState();
}

class _AdminHolidaysScreenState extends State<AdminHolidaysScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HolidayProvider>(context, listen: false).getHolidays();
    });
  }

  void _refreshHolidays() {
    Provider.of<HolidayProvider>(context, listen: false).getHolidays();
  }

  Future<void> _addHoliday() async {    
    final result = await showDialog<Holiday>(
      context: context,
      builder: (context) => AddHolidayDialog(),
    );

    if (result != null) {
      _refreshHolidays();
      SnackbarUtils.showSuccess(context, 'Holiday added successfully!');
    }
  }

  Future<void> _editHoliday(Holiday holiday) async {
    final result = await showDialog<Holiday>(
      context: context,
      builder: (context) => AddHolidayDialog(holiday: holiday),
    );

    if (result != null) {
      _refreshHolidays();
      SnackbarUtils.showSuccess(context, 'Holiday updated successfully!');
    }
  }

  Future<void> _deleteHoliday(Holiday holiday) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "${holiday.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final holidayProvider = Provider.of<HolidayProvider>(context, listen: false);
        await holidayProvider.deleteHoliday(holiday.id);
        _refreshHolidays();
        SnackbarUtils.showSuccess(context, 'Holiday deleted successfully!');
      } catch (e) {
        SnackbarUtils.showError(context, 'Failed to delete holiday: ${e.toString()}');
      }
    }
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
                style: AppTextStyles.heading.copyWith(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Only administrators can access this page.',
                style: AppTextStyles.body.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Holidays'),
        backgroundColor: Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshHolidays,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Year filter and add button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Filter by Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addHoliday,
                  icon: Icon(Icons.add),
                  label: Text('Add Holiday'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Holidays list
          Expanded(
            child: Consumer<HolidayProvider>(
              builder: (context, holidayProvider, child) {
                if (holidayProvider.isLoading) {
                  return CustomLoadingWidget.withMessage('Loading holidays...');
                }

                if (holidayProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading holidays',
                          style: AppTextStyles.subheading.copyWith(color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          holidayProvider.error!,
                          style: AppTextStyles.body.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshHolidays,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allHolidays = holidayProvider.holidays;
                final filteredHolidays = allHolidays
                    .where((holiday) => holiday.year == _selectedYear)
                    .toList();

                if (filteredHolidays.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No holidays found for $_selectedYear',
                          style: AppTextStyles.subheading.copyWith(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a new holiday to get started',
                          style: AppTextStyles.body.copyWith(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addHoliday,
                          icon: Icon(Icons.add),
                          label: Text('Add Holiday'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredHolidays.length,
                  itemBuilder: (context, index) {
                    final holiday = filteredHolidays[index];
                    return _buildHolidayCard(holiday);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayCard(Holiday holiday) {
    final parsedDate = holiday.date;
    final isPast = parsedDate.isBefore(DateTime.now());
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editHoliday(holiday),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Date indicator
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isPast ? Colors.grey[300] : Color(0xFF1976D2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPast ? Colors.grey[400]! : Color(0xFF1976D2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(parsedDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey[600] : Color(0xFF1976D2),
                      ),
                    ),
                    Text(
                      parsedDate.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey[600] : Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),

              // Holiday details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      holiday.title,
                      style: AppTextStyles.subheading.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          holiday.formattedDate,
                          style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        SizedBox(width: 80,
                          child: Text(overflow: TextOverflow.ellipsis,softWrap: true,
                            holiday.day,
                            style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          'Added by: ${holiday.action}',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              buildcolumn(holiday),
              // Action buttons
              // Column(
              //   children: [
              //     IconButton(
              //       icon: Icon(Icons.edit, color: Color(0xFF1976D2)),
              //       onPressed: () => _editHoliday(holiday),
              //       tooltip: 'Edit holiday',
              //     ),
              //     IconButton(
              //       icon: Icon(Icons.delete, color: Colors.red),
              //       onPressed: () => _deleteHoliday(holiday),
              //       tooltip: 'Delete holiday',
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
    

  }

  
  Widget buildcolumn(dynamic holiday){

    return Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Color(0xFF1976D2)),
                    onPressed: () => _editHoliday(holiday),
                    tooltip: 'Edit holiday',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteHoliday(holiday),
                    tooltip: 'Delete holiday',
                  ),
                ],
              );
  }
}
