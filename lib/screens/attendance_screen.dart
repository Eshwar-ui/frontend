import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/loading_dots_animation.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Calendar related variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Attendance>> _events = {};
  Map<DateTime, Holiday> _holidays = {};
  bool _isLoadingCalendarData = false;

  // Centralized attendance legend configuration
  static const Map<String, Map<String, dynamic>> _attendanceLegend = {
    'present': {
      'color': Colors.green,
      'icon': Icons.check_circle,
      'label': 'Present',
    },
    'halfday': {
      'color': Colors.orange,
      'icon': Icons.schedule,
      'label': 'Half Day',
    },
    'half day': {
      'color': Colors.orange,
      'icon': Icons.schedule,
      'label': 'Half Day',
    },
    'absent': {'color': Colors.red, 'icon': Icons.cancel, 'label': 'Absent'},
    'holiday': {
      'color': Colors.purple,
      'icon': Icons.celebration,
      'label': 'Holiday',
    },
    'weekend': {
      'color': Colors.grey,
      'icon': Icons.weekend,
      'label': 'Weekend',
    },
    'today': {'color': Colors.orange, 'icon': Icons.today, 'label': 'Today'},
    'selected': {
      'color': Color(0xFF1976D2),
      'icon': Icons.radio_button_checked,
      'label': 'Selected',
    },
  };

  // Helper method to get attendance color configuration
  Map<String, dynamic>? _getAttendanceConfig(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    return _attendanceLegend[normalizedStatus];
  }

  // Helper method to get color for status with fallback
  Color _getStatusColor(String status) {
    final config = _getAttendanceConfig(status);
    return config?['color'] ?? Colors.grey;
  }

  // Helper method to get icon for status with fallback
  IconData _getStatusIcon(String status) {
    final config = _getAttendanceConfig(status);
    return config?['icon'] ?? Icons.help_outline;
  }

  // Helper method to get a darker shade of a color for text
  Color _getDarkerShade(Color color) {
    return Color.fromRGBO(
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
      1.0,
    );
  }

  // Helper method to parse break time from various formats
  double _parseBreakTimeValue(dynamic breakValue) {
    try {
      // If it's already a number, return as is
      if (breakValue is num) {
        return breakValue.toDouble();
      }

      // If it's a string, check if it's a time format
      if (breakValue is String) {
        // Try to parse as UTC time string first
        try {
          final dateTime = DateTime.parse(breakValue).toLocal();
          // Calculate duration from midnight (break duration)
          final midnight = DateTime(
            dateTime.year,
            dateTime.month,
            dateTime.day,
          );
          final durationFromMidnight = dateTime.difference(midnight);
          return durationFromMidnight.inSeconds.toDouble();
        } catch (e) {
          // Not a UTC time string
        }

        // Try to parse as HH:MM format
        try {
          final parts = breakValue.split(':');
          if (parts.length >= 2) {
            final hours = int.parse(parts[0]);
            final minutes = int.parse(parts[1]);
            return ((hours * 3600) + (minutes * 60)).toDouble();
          }
        } catch (e) {
          // Not HH:MM format
        }

        // Try to parse as number string
        try {
          return double.parse(breakValue);
        } catch (e) {
          // Not a number string
        }
      }

      return 0.0;
    } catch (e) {
      print('Error parsing break time: $e');
      return 0.0;
    }
  }

  // Helper method to create synthetic Attendance object from date-wise data
  Attendance? _createSyntheticAttendance(
    Map<String, dynamic> dateData,
    DateTime date,
  ) {
    try {
      final totalWorkingTime = (dateData['totalWorkingTime'] ?? 0.0).toDouble();

      // Parse break time using the same logic as the model
      double totalBreakTime = 0.0;
      if (dateData['totalBreakTime'] != null) {
        totalBreakTime = _parseBreakTimeValue(dateData['totalBreakTime']);
      }

      print(
        '_createSyntheticAttendance: totalWorkingTime from API: $totalWorkingTime',
      );
      print(
        '_createSyntheticAttendance: totalBreakTime from API (raw): ${dateData['totalBreakTime']}',
      );
      print(
        '_createSyntheticAttendance: totalBreakTime parsed: $totalBreakTime seconds',
      );
      print(
        '_createSyntheticAttendance: dateData keys: ${dateData.keys.toList()}',
      );

      // Try to get actual punch times from the date-wise data
      DateTime? actualPunchIn;
      DateTime? actualPunchOut;

      try {
        if (dateData['firstPunchIn'] != null) {
          actualPunchIn = DateTime.parse(dateData['firstPunchIn'].toString());
        }
        if (dateData['lastPunchOut'] != null) {
          actualPunchOut = DateTime.parse(dateData['lastPunchOut'].toString());
        }
      } catch (e) {
        print('Error parsing punch times from date-wise data: $e');
      }

      // Create a synthetic attendance record with real times if available
      final attendance = Attendance(
        id: 'synthetic_${date.millisecondsSinceEpoch}',
        employeeId: '', // Will be filled from context
        punchIn:
            actualPunchIn ??
            date.add(Duration(hours: 9)), // Use actual or default
        punchOut: actualPunchOut, // Use actual time or null
        breakTime: totalBreakTime,
        totalWorkingTime: totalWorkingTime,
      );

      print(
        '_createSyntheticAttendance: Created attendance with breakTime: ${attendance.breakTime}',
      );
      print(
        '_createSyntheticAttendance: attendance.formattedBreakTime: ${attendance.formattedBreakTime}',
      );

      return attendance;
    } catch (e) {
      print('Error creating synthetic attendance: $e');
      return null;
    }
  }

  // Helper method to create absent attendance record
  Attendance _createAbsentAttendance(DateTime date) {
    return Attendance(
      id: 'absent_${date.millisecondsSinceEpoch}',
      employeeId: '', // Will be filled from context
      punchIn: date.add(Duration(hours: 9)), // Default time
      punchOut: null, // No punch out for absent days
      breakTime: 0.0,
      totalWorkingTime: 0.0, // Zero working time = absent
    );
  }

  // Helper method to add absent records for missing weekdays
  void _addAbsentForMissingWeekdays(
    Map<DateTime, List<Attendance>> events,
    Map<DateTime, Holiday> holidays,
    int month,
    int year,
  ) {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);

    // Get the number of days in the month
    final daysInMonth = DateTime(year, month + 1, 0).day;

    print(
      'Checking for missing weekdays in $month/$year (${daysInMonth} days)',
    );

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);

      // Only process dates up to today (don't mark future dates as absent)
      // For today, only mark as absent if it's past a reasonable time (e.g., 11 AM)
      if (date.isAfter(currentDate)) {
        continue;
      }

      // For today, check if it's past 11 AM before marking as absent
      if (date.isAtSameMomentAs(currentDate)) {
        final currentTime = DateTime.now();
        if (currentTime.hour < 11) {
          continue; // Too early to mark today as absent
        }
      }

      // Skip weekends (Saturday = 6, Sunday = 7)
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

      // Skip holidays
      if (holidays.containsKey(date)) {
        continue;
      }

      // Skip if we already have attendance data for this date
      if (events.containsKey(date) && events[date]!.isNotEmpty) {
        continue;
      }

      // This is a weekday with no attendance data - mark as absent
      if (events[date] == null) events[date] = [];
      events[date]!.add(_createAbsentAttendance(date));
      print('Marked date as absent: $date');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  void _loadAttendance() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      // Load attendance data for calendar
      _loadAttendanceForCalendar(user.employeeId);
    }
  }

  Future<void> _loadAttendanceForCalendar(String employeeId) async {
    if (mounted) {
      setState(() {
        _isLoadingCalendarData = true;
      });
    }

    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final holidayProvider = context.read<HolidayProvider>();

      // Load punches for the currently focused month/year instead of selected
      final focusedMonth = _focusedDay.month;
      final focusedYear = _focusedDay.year;

      print(
        'Loading attendance for calendar: month=$focusedMonth, year=$focusedYear',
      );

      // Try loading historical data using getDateWiseData instead of getPunches
      await attendanceProvider.getDateWiseData(
        employeeId,
        month: focusedMonth,
        year: focusedYear,
      );

      print(
        'DateWiseData returned ${attendanceProvider.dateWiseData.length} records',
      );

      // Also load current month punches for real-time data
      await attendanceProvider.getPunches(
        employeeId,
        month: focusedMonth,
        year: focusedYear,
      );

      print(
        'AttendanceProvider returned ${attendanceProvider.punches.length} punches',
      );
      print('AttendanceProvider isLoading: ${attendanceProvider.isLoading}');
      print('AttendanceProvider error: ${attendanceProvider.error}');

      // Load holidays for the focused year
      await holidayProvider.getHolidaysByYear(focusedYear);

      // Group attendance by date from both sources
      final Map<DateTime, List<Attendance>> events = {};

      // Process punch data (current/recent data)
      print('Processing ${attendanceProvider.punches.length} punch records');

      for (var attendance in attendanceProvider.punches) {
        final date = DateTime(
          attendance.punchIn.year,
          attendance.punchIn.month,
          attendance.punchIn.day,
        );
        if (events[date] == null) events[date] = [];
        events[date]!.add(attendance);
        print(
          'Added punch data for date: $date, status: ${attendance.attendanceStatus}',
        );
      }

      // Process date-wise data (historical data)
      print(
        'Processing ${attendanceProvider.dateWiseData.length} date-wise records',
      );

      for (var dateData in attendanceProvider.dateWiseData) {
        try {
          // Parse the date from dateWiseData format (likely dd-MM-yyyy)
          final dateStr = dateData['_id'] as String?;
          if (dateStr != null) {
            final dateParts = dateStr.split('-');
            if (dateParts.length == 3) {
              final day = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final year = int.parse(dateParts[2]);
              final date = DateTime(year, month, day);

              // Create a synthetic Attendance object from date-wise data
              final syntheticAttendance = _createSyntheticAttendance(
                dateData,
                date,
              );
              if (syntheticAttendance != null) {
                if (events[date] == null) events[date] = [];
                // Only add if we don't already have punch data for this date
                if (!events[date]!.any(
                  (a) =>
                      a.punchIn.day == date.day &&
                      a.punchIn.month == date.month &&
                      a.punchIn.year == date.year,
                )) {
                  events[date]!.add(syntheticAttendance);
                  print(
                    'Added synthetic attendance for date: $date, status: ${syntheticAttendance.attendanceStatus}',
                  );
                }
              }
            }
          }
        } catch (e) {
          print('Error processing date-wise data: $e');
        }
      }

      // Group holidays by date
      final Map<DateTime, Holiday> holidayMap = {};
      print('Processing ${holidayProvider.holidays.length} holidays');

      for (var holiday in holidayProvider.holidays) {
        final date = DateTime(
          holiday.date.year,
          holiday.date.month,
          holiday.date.day,
        );
        holidayMap[date] = holiday;
        print('Added holiday for date: $date, title: ${holiday.title}');
      }

      // Add absent records for missing weekdays
      _addAbsentForMissingWeekdays(
        events,
        holidayMap,
        focusedMonth,
        focusedYear,
      );

      print('Final events count: ${events.length} dates with attendance data');

      if (mounted) {
        setState(() {
          _events = events;
          _holidays = holidayMap;
        });
      }
    } catch (e) {
      print('Error loading attendance for calendar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCalendarData = false;
        });
      }
    }
  }

  List<Attendance> _getEventsForDay(DateTime day) {
    try {
      final date = DateTime(day.year, day.month, day.day);
      return _events[date] ?? [];
    } catch (e) {
      print('Error getting events for day: $e');
      return [];
    }
  }

  Holiday? _getHolidayForDay(DateTime day) {
    try {
      final date = DateTime(day.year, day.month, day.day);
      return _holidays[date];
    } catch (e) {
      print('Error getting holiday for day: $e');
      return null;
    }
  }

  Future<void> _punchIn() async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final user = authProvider.user;

    if (user != null) {
      final result = await attendanceProvider.punchIn(
        user.employeeId,
        user.fullName,
      );
      if (result['message'] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        // Refresh data after a short delay to avoid setState during build
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _loadAttendance();
          }
        });
      }
    }
  }

  Future<void> _punchOut() async {
    final authProvider = context.read<AuthProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final user = authProvider.user;

    if (user != null) {
      final result = await attendanceProvider.punchOut(
        user.employeeId,
        user.fullName,
      );
      if (result['message'] != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
        // Refresh data after a short delay to avoid setState during build
        Future.delayed(Duration(milliseconds: 100), () {
          if (mounted) {
            _loadAttendance();
          }
        });
      }
    }
  }

  bool _isPunchedInToday() {
    try {
      final today = DateTime.now();
      final todayEvents = _getEventsForDay(today);
      return todayEvents.any((attendance) => attendance.isPunchedIn);
    } catch (e) {
      print('Error checking punch in status: $e');
      return false;
    }
  }

  Widget _buildPunchButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isPunchedInToday() ? null : _punchIn,
              icon: Icon(Icons.login),
              label: Text('Punch In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isPunchedInToday() ? _punchOut : null,
              icon: Icon(Icons.logout),
              label: Text('Punch Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenLoader() {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.white)),
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingDotsAnimation(
                    color: Color(0xFF1976D2),
                    size: 8,
                    dotCount: 3,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading attendance... ',
                    style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingCalendarData
          ? _buildFullScreenLoader()
          : Column(
              children: [
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 170,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.25),
                        offset: Offset(0, 0),
                        blurRadius: 20,
                      ),
                    ],
                    color: Color.fromRGBO(255, 255, 255, 1),
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    // spacing: 16,
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        spacing: 8,

                        children: [
                          Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: <Widget>[
                                Text(
                                  '07:30',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(76, 175, 80, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 22.074867248535156,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Average Working Hours',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(140, 140, 140, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 14.716577529907227,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Divider(
                              color: Colors.black,

                              thickness: 1, // line thickness
                              indent: 0, // empty space to the left
                              endIndent: 0,
                            ),
                          ),
                          Container(
                            color: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: <Widget>[
                                Text(
                                  '06:30 PM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(76, 175, 80, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 21,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 4.598930835723877),
                                Text(
                                  'Average Out Time',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(140, 140, 140, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 14.716577529907227,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        spacing: 8,
                        children: [
                          Container(
                            decoration: BoxDecoration(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: <Widget>[
                                Text(
                                  '09:30 AM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(76, 175, 80, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 22.074867248535156,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 4.598930835723877),
                                Text(
                                  'Average In Time',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(140, 140, 140, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 14.716577529907227,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 150,
                            child: Divider(
                              color: Colors.black,

                              thickness: 1, // line thickness
                              indent: 0, // empty space to the left
                              endIndent: 0,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: <Widget>[
                                Text(
                                  '01:00 ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(76, 175, 80, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 22.074867248535156,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 4.598930835723877),
                                Text(
                                  'Average Break Time',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color.fromRGBO(140, 140, 140, 1),
                                    fontFamily: 'Poppins',
                                    fontSize: 14.716577529907227,
                                    letterSpacing:
                                        0 /*percentages not used in flutter. defaulting to zero*/,
                                    fontWeight: FontWeight.normal,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Punch In/Out Buttons
                _buildPunchButtons(),
                // _buildFilter(),
                Expanded(child: _buildCalendarView()),
              ],
            ),
    );
  }

  Widget _buildCalendarView() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLoadingCalendarData)
            Container(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading attendance data...',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          SizedBox(
            // height: 400, // Give TableCalendar a fixed height
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                // Show details after setState completes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showAttendanceDetails(selectedDay);
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                // Reload attendance data for the new month
                final authProvider = context.read<AuthProvider>();
                final user = authProvider.user;
                if (user != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadAttendanceForCalendar(user.employeeId);
                  });
                }
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.grey[600]),
                holidayTextStyle: TextStyle(color: Colors.purple),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                defaultDecoration: BoxDecoration(shape: BoxShape.circle),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                titleTextStyle: AppTextStyles.subheading,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  return _buildCalendarDay(date);
                },
                selectedBuilder: (context, date, _) {
                  return _buildCalendarDay(date, isSelected: true);
                },
                todayBuilder: (context, date, _) {
                  return _buildCalendarDay(date, isToday: true);
                },
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty && events.first != null) {
                    final attendance = events.first as Attendance;
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getMarkerColor(attendance.attendanceStatus),
                        ),
                        width: 8,
                        height: 8,
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final events = _getEventsForDay(date);
    final holiday = _getHolidayForDay(date);
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Debug log for specific dates
    if (events.isNotEmpty || holiday != null) {
      print(
        'Calendar Day ${date.day}/${date.month}: events=${events.length}, holiday=${holiday?.title}',
      );
    }

    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;

    // Check for holiday first (highest priority)
    if (holiday != null) {
      final holidayColor = _getStatusColor('holiday');
      backgroundColor = holidayColor.withOpacity(0.2);
      textColor = _getDarkerShade(holidayColor);
    }
    // Then check attendance status
    else if (events.isNotEmpty) {
      try {
        final attendance = events.first;

        // Get attendance status from the model
        String attendanceStatus = attendance.attendanceStatus;
        if (attendanceStatus.isEmpty) {
          attendanceStatus = 'absent'; // Default to absent if no status
        }

        // Debug log for calendar days
        print(
          'Calendar Day ${date.day}/${date.month}: ID=${attendance.id}, Status=${attendanceStatus}, WorkingTime=${attendance.totalWorkingTime}',
        );

        // Check if there are incomplete check-ins (no check-out)
        bool hasIncompleteCheckIn = attendance.isPunchedIn;

        String effectiveStatus = attendanceStatus.toLowerCase().trim();

        // If there are incomplete check-ins, treat as absent
        if (hasIncompleteCheckIn && effectiveStatus != 'absent') {
          effectiveStatus = 'absent';
        }

        // Use centralized color configuration
        final statusColor = _getStatusColor(effectiveStatus);
        backgroundColor = statusColor.withOpacity(0.2);
        textColor = _getDarkerShade(statusColor);
      } catch (e) {
        print('Error processing attendance data for calendar day: $e');
        // Fallback to default styling
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700] ?? Colors.grey;
      }
    }
    // Then check if it's weekend
    else if (isWeekend) {
      final weekendColor = _getStatusColor('weekend');
      backgroundColor = weekendColor.withOpacity(0.1);
      textColor = _getDarkerShade(weekendColor);
    }

    // Override colors for selected and today states
    if (isSelected) {
      backgroundColor = _getStatusColor('selected');
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = _getStatusColor('today');
      textColor = Colors.white;
    }

    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isSelected || isToday
            ? Border.all(color: Colors.white, width: 2)
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            if (holiday != null)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    // Define the order of legend items to display
    final legendOrder = [
      'present',
      'halfday',
      'absent',
      'holiday',
      'weekend',
      'today',
      'selected',
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Legend',
            style: AppTextStyles.subheading.copyWith(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: legendOrder.map((status) {
              final config = _getAttendanceConfig(status);
              if (config != null) {
                return _buildLegendItem(
                  config['label'] as String,
                  config['color'] as Color,
                  config['icon'] as IconData,
                );
              }
              return SizedBox.shrink(); // Return empty widget if config not found
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getMarkerColor(String status) {
    return _getStatusColor(status);
  }

  // Commented out the existing attendance list
  /*
  Widget _buildAttendanceList(List<Attendance> attendanceList) {
    return ListView.builder(
      itemCount: attendanceList.length,
      itemBuilder: (context, index) {
        final attendance = attendanceList[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 150,
                  child: Text(
                    DateFormat.yMMMMEEEEd().format(attendance.date),
                    style: AppTextStyles.subheading,
                  ),
                ),
                _buildStatusChip(attendance.status),
              ],
            ),
            children: [
              _buildInfoRow(
                Icons.timer,
                'Total Working Time',
                _formatDuration(attendance.totalWorkingTime),
              ),
              _buildInfoRow(
                Icons.free_breakfast,
                'Total Break Time',
                _formatDuration(attendance.totalBreakTime),
              ),
              SizedBox(height: 16),
              ...attendance.checkIns.map((checkIn) {
                final duration = checkIn.checkOutTime != null
                    ? checkIn.checkOutTime!.difference(checkIn.checkInTime)
                    : Duration.zero;
                return Column(
                  children: [
                    _buildInfoRow(
                      Icons.login,
                      'Check In',
                      DateFormat.jm().format(checkIn.checkInTime.toLocal()),
                    ),
                    _buildInfoRow(
                      Icons.logout,
                      'Check Out',
                      checkIn.checkOutTime != null
                          ? DateFormat.jm().format(
                              checkIn.checkOutTime!.toLocal(),
                            )
                          : '-',
                    ),
                    _buildInfoRow(
                      Icons.schedule,
                      'Duration',
                      _formatDuration(duration.inMilliseconds.toDouble()),
                    ),
                    Divider(thickness: 1, color: Colors.grey.shade300),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
  */

  // ignore: unused_element
  Widget _buildStatusChip(String status) {
    final chipColor = _getStatusColor(status);

    return Chip(
      label: Text(
        status,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide.none,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  void _showAttendanceDetails(DateTime selectedDate) {
    final events = _getEventsForDay(selectedDate);
    final holiday = _getHolidayForDay(selectedDate);
    final isWeekend =
        selectedDate.weekday == DateTime.saturday ||
        selectedDate.weekday == DateTime.sunday;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildAttendanceModal(selectedDate, events, holiday, isWeekend),
    );
  }

  Widget _buildAttendanceModal(
    DateTime date,
    List<Attendance> events,
    Holiday? holiday,
    bool isWeekend,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Date header
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF1976D2),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(date),
                        style: AppTextStyles.subheading.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Status indicator
                  _buildStatusIndicator(events, holiday, isWeekend),
                  SizedBox(height: 20),

                  // Attendance details
                  if (events.isNotEmpty) ...[
                    _buildAttendanceSection(events.first),
                  ] else if (holiday != null) ...[
                    _buildHolidaySection(holiday),
                  ] else if (isWeekend) ...[
                    _buildWeekendSection(),
                  ] else ...[
                    _buildNoDataSection(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(
    List<Attendance> events,
    Holiday? holiday,
    bool isWeekend,
  ) {
    String status;
    Color statusColor;
    IconData statusIcon;
    String? additionalInfo;

    if (holiday != null) {
      status = 'Holiday - ${holiday.title}';
      statusColor = _getStatusColor('holiday');
      statusIcon = _getStatusIcon('holiday');
    } else if (events.isNotEmpty) {
      try {
        final attendance = events.first;

        // Get attendance status
        String attendanceStatus = attendance.attendanceStatus;
        if (attendanceStatus.isEmpty) {
          attendanceStatus = 'absent'; // Default to absent if no status
        }

        // Check if there are incomplete check-ins
        bool hasIncompleteCheckIn = attendance.isPunchedIn;

        String effectiveStatus = attendanceStatus.toLowerCase().trim();

        if (hasIncompleteCheckIn && effectiveStatus != 'absent') {
          status = 'ABSENT';
          statusColor = _getStatusColor('absent');
          statusIcon = _getStatusIcon('absent');
          additionalInfo = 'Marked absent due to incomplete check-out';
        } else {
          status = attendanceStatus.toUpperCase();
          statusColor = _getStatusColor(effectiveStatus);
          statusIcon = _getStatusIcon(effectiveStatus);
        }
      } catch (e) {
        print('Error processing attendance status: $e');
        status = 'ERROR';
        statusColor = Colors.grey;
        statusIcon = Icons.error_outline;
        additionalInfo = 'Error loading attendance data';
      }
    } else if (isWeekend) {
      status = 'Weekend';
      statusColor = _getStatusColor('weekend');
      statusIcon = _getStatusIcon('weekend');
    } else {
      status = 'No Data';
      statusColor = Colors.grey;
      statusIcon = Icons.info_outline;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (additionalInfo != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    additionalInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(Attendance attendance) {
    // Determine if this is a synthetic record (absent/system generated)
    final isSyntheticRecord =
        attendance.id.startsWith('synthetic_') ||
        attendance.id.startsWith('absent_');
    final isAbsentRecord =
        attendance.id.startsWith('absent_') ||
        attendance.attendanceStatus.toLowerCase() == 'absent';

    // Get accurate working time
    final workingHours =
        attendance.totalWorkingTime /
        3600000; // Convert milliseconds to hours for color coding

    // Debug logging
    print('Building attendance section for: ${attendance.id}');
    print('Total Working Time (raw): ${attendance.totalWorkingTime}');
    print('Working Hours (calculated): $workingHours');
    print('Attendance Status: ${attendance.attendanceStatus}');
    print('Punch In (Local): ${attendance.punchIn.toLocal()}');
    print('Punch Out (Local): ${attendance.punchOut?.toLocal()}');
    print('Is Synthetic: $isSyntheticRecord, Is Absent: $isAbsentRecord');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Details',
          style: AppTextStyles.subheading.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),

        // Status summary with accurate information
        // Container(
        //   padding: EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: _getStatusColor(
        //       effectiveStatus.toLowerCase(),
        //     ).withOpacity(0.1),
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(
        //       color: _getStatusColor(
        //         effectiveStatus.toLowerCase(),
        //       ).withOpacity(0.3),
        //     ),
        //   ),
        //   child: Row(
        //     children: [
        //       Icon(
        //         _getStatusIcon(effectiveStatus.toLowerCase()),
        //         color: _getStatusColor(effectiveStatus.toLowerCase()),
        //         size: 20,
        //       ),
        //       SizedBox(width: 8),
        //       Text(
        //         'Status: $effectiveStatus',
        //         style: TextStyle(
        //           fontWeight: FontWeight.bold,
        //           color: _getStatusColor(effectiveStatus.toLowerCase()),
        //         ),
        //       ),
        //       if (isSyntheticRecord) ...[
        //         SizedBox(width: 8),
        //         Container(
        //           padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        //           decoration: BoxDecoration(
        //             color: Colors.grey[300],
        //             borderRadius: BorderRadius.circular(4),
        //           ),
        //           child: Text(
        //             'Auto-generated',
        //             style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        //           ),
        //         ),
        //       ],
        //     ],
        //   ),
        // ),
        // SizedBox(height: 16),

        // Summary cards with accurate data
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Working Hours',
                attendance.formattedWorkingTime,
                Icons.timer,
                _getStatusColor(attendance.attendanceStatus.toLowerCase()),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Break Time',
                attendance.formattedBreakTime,
                Icons.free_breakfast,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Time Details - show based on data availability
        if (!isAbsentRecord) ...[
          Text(
            'Time Details',
            style: AppTextStyles.subheading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),

          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                // Show punch times for all non-absent records
                if (!isAbsentRecord) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeDetail(
                          'Punch In',
                          _formatTime(attendance.punchIn),
                          Icons.login,
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeDetail(
                          'Punch Out',
                          attendance.punchOut != null
                              ? _formatTime(attendance.punchOut!)
                              : (attendance.isPunchedIn
                                    ? 'Still Active'
                                    : 'Not Available'),
                          Icons.logout,
                          attendance.punchOut != null
                              ? Colors.red
                              : attendance.isPunchedIn
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],

                // Always show duration information
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeDetail(
                        'Total Duration',
                        attendance.formattedWorkingTime,
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                    if (attendance.breakTime > 0) ...[
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeDetail(
                          'Break Duration',
                          attendance.formattedBreakTime,
                          Icons.coffee,
                          Colors.brown,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // Show absent day information
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.cancel, size: 48, color: Colors.red[600]),
                SizedBox(height: 12),
                Text(
                  'No Attendance Record',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'No check-in or check-out activity was recorded for this working day.',
                  style: TextStyle(fontSize: 14, color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Helper method to format time consistently
  String _formatTime(DateTime dateTime) {
    try {
      return DateFormat.jm().format(dateTime.toLocal());
    } catch (e) {
      return 'Invalid Time';
    }
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetail(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHolidaySection(Holiday holiday) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, size: 48, color: Colors.purple),
          SizedBox(height: 16),
          Text(
            holiday.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Enjoy your holiday!',
            style: TextStyle(fontSize: 14, color: Colors.purple[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.weekend, size: 48, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text(
            'Weekend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Time to relax and recharge!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey[600]),
          SizedBox(height: 16),
          Text(
            'No Attendance Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'No check-in or check-out records found for this date.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
