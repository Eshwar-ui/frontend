import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/loading_dots_animation.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AddHolidayDialog extends StatefulWidget {
  final Holiday? holiday;

  const AddHolidayDialog({Key? key, this.holiday}) : super(key: key);

  @override
  _AddHolidayDialogState createState() => _AddHolidayDialogState();
}

class _AddHolidayDialogState extends State<AddHolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _holidayNameController = TextEditingController();
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.holiday != null;
    
    if (_isEditMode) {
      _holidayNameController.text = widget.holiday!.title;
      _selectedDate = widget.holiday!.date;
    }
  }

  @override
  void dispose() {
    _holidayNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  String _formatDateForAPI(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  Future<void> _saveHoliday() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      SnackbarUtils.showError(context, 'Please select a date');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final holidayName = _holidayNameController.text.trim();
      final dateString = _formatDateForAPI(_selectedDate!);
      final dayName = _getDayName(_selectedDate!);
      final postBy = currentUser.firstName;

      final holidayProvider = Provider.of<HolidayProvider>(context, listen: false);
      Map<String, dynamic> result;

      if (_isEditMode) {
        // Update existing holiday
        result = await holidayProvider.updateHoliday(widget.holiday!.id, 
          title: holidayName,
          date: dateString,
          day: dayName,
        );
      } else {
        // Add new holiday
        result = await holidayProvider.addHoliday(
          title: holidayName,
          date: dateString,
          action: postBy,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Navigator.of(context).pop();
        SnackbarUtils.showSuccess(context, result['message'] ?? 'Holiday saved successfully!');
      } else {
        throw Exception(result['message'] ?? 'Failed to save holiday');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = 'Unknown error occurred';
      if (e.toString().contains('duplicate') || e.toString().contains('already exists')) {
        errorMessage = 'A holiday already exists on this date';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      SnackbarUtils.showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.add,
                    color: Color(0xFF1976D2),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    _isEditMode ? 'Edit Holiday' : 'Add New Holiday',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Holiday name field
              TextFormField(
                controller: _holidayNameController,
                decoration: InputDecoration(
                  labelText: 'Holiday Name',
                  hintText: 'e.g., New Year, Christmas, Independence Day',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.celebration),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a holiday name';
                  }
                  if (value.trim().length < 3) {
                    return 'Holiday name must be at least 3 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 20),

              // Date selection
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Holiday Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                                  : 'Select a date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate != null ? Colors.black : Colors.grey[600],
                                fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Preview section
              if (_selectedDate != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF1976D2).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.celebration, size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            _holidayNameController.text.isNotEmpty 
                                ? _holidayNameController.text 
                                : 'Holiday Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            _formatDateForAPI(_selectedDate!),
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Color(0xFF1976D2)),
                          SizedBox(width: 8),
                          Text(
                            _getDayName(_selectedDate!),
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveHoliday,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? LoadingDotsAnimation(
                              color: Colors.white,
                              size: 6,
                            )
                          : Text(_isEditMode ? 'Update Holiday' : 'Add Holiday'),
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
