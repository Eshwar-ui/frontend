import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';

class new_calender_screen extends StatefulWidget {
  const new_calender_screen({super.key});

  @override
  State<new_calender_screen> createState() => _new_calender_screenState();
}

class _new_calender_screenState extends State<new_calender_screen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  // Centralized attendance legend configuration (same as attendance_screen.dart)
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
  Color _getStatusColorEnhanced(String status) {
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final employeeId = user?.employeeId;
    if (employeeId == null) return;

    final attendance = Provider.of<AttendanceProvider>(context, listen: false);
    final holidayProv = Provider.of<HolidayProvider>(context, listen: false);

    await Future.wait([
      attendance.getDateWiseData(
        employeeId,
        month: _focusedDay.month,
        year: _focusedDay.year,
      ),
      holidayProv.getHolidaysByYear(_focusedDay.year),
    ]);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      final monthChanged =
          _focusedDay.month != selectedDay.month ||
          _focusedDay.year != selectedDay.year;
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      if (monthChanged) _loadData();
      // No longer show bottom sheet on calendar cell click
    }
  }

  Widget _buildDayDetails(DateTime date) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final employeeId = user?.employeeId ?? '';
    final attendance = Provider.of<AttendanceProvider>(context, listen: false);
    final holidays = Provider.of<HolidayProvider>(context, listen: false);
    final dateWiseData = attendance.getEmployeeDateWiseData(employeeId);
    final holidayList = holidays.holidays;

    final status = _getAttendanceStatus(date, dateWiseData, holidayList);
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    final key =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final dayData = dateWiseData.firstWhere(
      (d) => d['_id'] == key,
      orElse: () => {'totalWorkingTime': 0.0, 'punches': []},
    );
    final workingHours =
        ((dayData['totalWorkingTime'] ?? 0.0) as num).toDouble() / 3600.0;
    final punches = (dayData['punches'] as List?) ?? [];

    // Get break hours from backend (already calculated)
    final breakHours =
        ((dayData['totalBreakTime'] ?? 0.0) as num).toDouble() / 3600.0;

    print(
      'Break time from backend: ${dayData['totalBreakTime']} seconds = $breakHours hours',
    );

    // Get first punch in and last punch out
    DateTime? firstPunchIn;
    DateTime? lastPunchOut;

    // Try to get from dayData first (from date-wise API response)
    try {
      if (dayData['firstPunchIn'] != null) {
        firstPunchIn = DateTime.parse(dayData['firstPunchIn'].toString());
      }
      if (dayData['lastPunchOut'] != null) {
        lastPunchOut = DateTime.parse(dayData['lastPunchOut'].toString());
      }
    } catch (e) {
      print('Error parsing firstPunchIn/lastPunchOut from dayData: $e');
    }

    // Fallback: try to extract from punches array if not found in dayData
    if ((firstPunchIn == null || lastPunchOut == null) && punches.isNotEmpty) {
      try {
        final sortedPunches = List<Map<String, dynamic>>.from(punches);
        sortedPunches.sort((a, b) {
          final aTime = a['punchIn'] != null
              ? DateTime.parse(a['punchIn'])
              : DateTime(0);
          final bTime = b['punchIn'] != null
              ? DateTime.parse(b['punchIn'])
              : DateTime(0);
          return aTime.compareTo(bTime);
        });

        if (firstPunchIn == null && sortedPunches.first['punchIn'] != null) {
          firstPunchIn = DateTime.parse(sortedPunches.first['punchIn']);
        }

        // Find last punch out
        if (lastPunchOut == null) {
          for (var punch in sortedPunches.reversed) {
            if (punch['punchOut'] != null) {
              lastPunchOut = DateTime.parse(punch['punchOut']);
              break;
            }
          }
        }
      } catch (e) {
        print('Error parsing punch times from punches array: $e');
      }
    }

    print('=== Calendar Bottom Sheet Data ===');
    print('Date: $date');
    print('Day Data Keys: ${dayData.keys.toList()}');
    print('First Punch In (UTC): $firstPunchIn');
    print('First Punch In (Local): ${firstPunchIn?.toLocal()}');
    print('Last Punch Out (UTC): $lastPunchOut');
    print('Last Punch Out (Local): ${lastPunchOut?.toLocal()}');
    print(
      'Working Hours (from backend): ${workingHours.toStringAsFixed(2)} hours',
    );
    print('Break Hours (from backend): ${breakHours.toStringAsFixed(2)} hours');
    print('Number of punches: ${punches.length}');
    print('================================');

    // Check for holiday
    final holiday = holidayList.firstWhere(
      (h) => isSameDay(h.date, date),
      orElse: () =>
          Holiday(id: '', title: '', date: DateTime.now(), day: '', action: ''),
    );

    return _buildDayDetailsWidget(
      date,
      status,
      color,
      icon,
      workingHours,
      breakHours,
      firstPunchIn,
      lastPunchOut,
      holiday,
    );
  }

  Widget _buildDayDetailsWidget(
    DateTime date,
    String status,
    Color color,
    IconData icon,
    double workingHours,
    double breakHours,
    DateTime? firstPunchIn,
    DateTime? lastPunchOut,
    Holiday holiday,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with date and status
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color, size: 24),
                          SizedBox(height: 2),
                          Text(
                            '${date.day}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              if (status.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 20, color: color),
                        SizedBox(width: 8),
                        Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Holiday info
              if (holiday.id.isNotEmpty) ...[
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.withOpacity(0.1),
                          Colors.purple.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.celebration, color: Colors.purple, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Holiday',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.purple[800],
                                ),
                              ),
                              Text(
                                holiday.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple[900],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // First Punch In
              if (firstPunchIn != null) ...[
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.login,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'First Punch In',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(firstPunchIn.toLocal()),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Last Punch Out
              if (lastPunchOut != null) ...[
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Punch Out',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              DateFormat(
                                'h:mm a',
                              ).format(lastPunchOut.toLocal()),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Working Hours
              ...[
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Working Hours',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              _formatHours(workingHours),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Break Hours
              ...[
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle_outline,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Break Hours',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              _formatHours(breakHours),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  List<DateTime> _weekFor(DateTime anchor) {
    final monday = anchor.subtract(Duration(days: anchor.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }

  String _getAttendanceStatus(
    DateTime date,
    List<Map<String, dynamic>> dateWiseData,
    List<Holiday> holidays,
  ) {
    final key =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final day = dateWiseData.firstWhere(
      (d) => d['_id'] == key,
      orElse: () => {},
    );

    // Check for weekend first
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      // If there's no activity on a weekend, mark it as 'Weekend'
      if (day.isEmpty) {
        return 'Weekend';
      }
      // If there is activity, proceed to calculate status
    }

    // Check for holiday
    final holiday = holidays.firstWhere(
      (h) => isSameDay(h.date, date),
      orElse: () =>
          Holiday(id: '', title: '', date: DateTime.now(), day: '', action: ''),
    );
    if (holiday.id.isNotEmpty) return 'Holiday';

    // First, check if backend provides a status field directly
    if (day.containsKey('status') && day['status'] != null) {
      final backendStatus = day['status'].toString().trim();
      // Normalize the status string
      if (backendStatus.isNotEmpty && backendStatus.toLowerCase() != 'null') {
        // Return the backend status with proper capitalization
        final normalizedStatus =
            backendStatus.substring(0, 1).toUpperCase() +
            backendStatus.substring(1).toLowerCase();
        print(
          '📅 Date $key: Backend status = $backendStatus -> $normalizedStatus',
        );
        return normalizedStatus;
      }
    }

    // Fallback: Calculate status from working hours if no status provided
    if (day.containsKey('totalWorkingTime')) {
      final workingHours =
          ((day['totalWorkingTime'] ?? 0.0) as num).toDouble() / 3600.0;

      // Present: >= 7.5 hours (7h 30m)
      if (workingHours >= 7.5) {
        print(
          '📅 Date $key: Calculated status = Present (${workingHours.toStringAsFixed(2)}h)',
        );
        return 'Present';
      }

      // Half Day: >= 3.5 hours (3h 30m) but < 7.5 hours
      if (workingHours >= 3.5) {
        print(
          '📅 Date $key: Calculated status = Half Day (${workingHours.toStringAsFixed(2)}h)',
        );
        return 'Half Day';
      }

      // Less than 3.5 hours: Mark as Absent for past dates
      if (workingHours > 0) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (date.isBefore(today)) {
          print(
            '📅 Date $key: Calculated status = Absent (${workingHours.toStringAsFixed(2)}h < 3.5h required)',
          );
          return 'Absent';
        }
      }
    }

    // Only mark as absent if it's a past weekday
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) {
      print('📅 Date $key: Status = Absent (past date, no data)');
      return 'Absent';
    }

    // Future dates or current day with no data
    print('📅 Date $key: Status = Empty (future/current date, no data)');
    return '';
  }

  Color _getStatusColor(String status) {
    return _getStatusColorEnhanced(status);
  }

  Widget _buildCalendar(
    List<Map<String, dynamic>> dateWiseData,
    List<Holiday> holidays,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F9FC), Color(0xFFFFFFFF)],
              ),
        color: isDark ? theme.cardColor : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.08)),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.9),
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom header with gradient
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withOpacity(0.8),
                      ]
                    : [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.primary.withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    });
                    _loadData();
                  },
                  icon: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedDay),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                      );
                    });
                    _loadData();
                  },
                  icon: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadData();
            },
            headerVisible:
                false, // Hide default header since we have custom one
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              weekendStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              holidayTextStyle: TextStyle(color: colorScheme.secondary),
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) =>
                  _buildDayCell(date, dateWiseData, holidays, false, false),
              selectedBuilder: (context, date, _) =>
                  _buildDayCell(date, dateWiseData, holidays, true, false),
              todayBuilder: (context, date, _) =>
                  _buildDayCell(date, dateWiseData, holidays, false, true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    List<Map<String, dynamic>> dateWiseData,
    List<Holiday> holidays,
    bool isSelected,
    bool isToday,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final status = _getAttendanceStatus(date, dateWiseData, holidays);
    final color = _getStatusColor(status);

    Color backgroundColor = Colors.transparent;
    Color textColor = colorScheme.onSurface;
    List<BoxShadow>? shadows;

    // Check for holiday first (highest priority)
    final holiday = holidays.firstWhere(
      (h) => isSameDay(h.date, date),
      orElse: () =>
          Holiday(id: '', title: '', date: DateTime.now(), day: '', action: ''),
    );

    if (holiday.id.isNotEmpty) {
      final holidayColor = _getStatusColor('holiday');
      backgroundColor = holidayColor.withOpacity(0.2);
      textColor = _getDarkerShade(holidayColor);
      shadows = [
        BoxShadow(
          color: holidayColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    // Then check attendance status
    else if (status == 'Weekend') {
      final weekendColor = _getStatusColor('weekend');
      backgroundColor = isDark
          ? weekendColor.withOpacity(0.1)
          : weekendColor.withOpacity(0.08);
      textColor = _getDarkerShade(weekendColor);
    } else if (status.isNotEmpty) {
      // Show all statuses including Absent
      backgroundColor = color.withOpacity(isDark ? 0.25 : 0.2);
      textColor = isDark ? color.withOpacity(0.9) : _getDarkerShade(color);
      shadows = [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        if (!isDark)
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
      ];
    }

    // Override colors for selected and today states
    if (isSelected) {
      backgroundColor = _getStatusColor('selected');
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: _getStatusColor('selected').withOpacity(0.5),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ];
    } else if (isToday) {
      backgroundColor = _getStatusColor('today');
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: _getStatusColor('today').withOpacity(0.5),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ];
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isSelected || isToday ? 1.05 : 1.0,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: (isSelected || isToday)
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                  )
                : null,
            color: (isSelected || isToday) ? null : backgroundColor,
            shape: BoxShape.circle,
            border: isSelected || isToday
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: shadows,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isSelected || isToday
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: textColor,
                    shadows: (isSelected || isToday)
                        ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 2),
                // if (!isSelected &&
                //     !isToday &&
                //     status.isNotEmpty &&
                //     status != 'Weekend')
                //   Container(
                //     width: 6,
                //     height: 6,
                //     decoration: BoxDecoration(
                //       color: color,
                //       shape: BoxShape.circle,
                //       boxShadow: [
                //         BoxShadow(
                //           color: color.withOpacity(0.5),
                //           blurRadius: 3,
                //           offset: Offset(0, 1),
                //         ),
                //       ],
                //     ),
                //   ),
              ],
            ),
          ),
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? colorScheme.surface : colorScheme.surface;
    final textColor = isDark ? colorScheme.onSurface : Colors.grey[800];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Legend',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: legendOrder.map((status) {
              final config = _getAttendanceConfig(status);
              if (config != null) {
                // For highest contrast and a slightly lighter/darker dot for dark/light theme
                final dotColor = isDark
                    ? (config['color'] as Color).withOpacity(0.8)
                    : (config['color'] as Color);
                final labelColor = isDark
                    ? colorScheme.onSurface
                    : Colors.grey[700];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: isDark
                            ? Border.all(
                                color: colorScheme.outline.withOpacity(0.32),
                                width: 1,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(config['icon'] as IconData, size: 16, color: dotColor),
                    SizedBox(width: 4),
                    Text(
                      config['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }
              return SizedBox.shrink();
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
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

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  // ignore: unused_element
  String _formatPunch(String? inStr, String? outStr) {
    String fmt(String? s) {
      if (s == null) return '--:--';
      try {
        final dt = DateTime.parse(s);
        final h12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final m = dt.minute.toString().padLeft(2, '0');
        final ap = dt.hour >= 12 ? 'PM' : 'AM';
        return '$h12:$m $ap';
      } catch (_) {
        return s;
      }
    }

    final inText = fmt(inStr);
    final outText = fmt(outStr);
    return outText != '--:--' ? '$inText - $outText' : 'Punched In: $inText';
  }

  // ignore: unused_element
  String _formatDateRange(DateTime start, DateTime end) {
    if (start.month == end.month && start.year == end.year) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}';
    }
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
  }

  // ignore: unused_element
  Widget _buildTimeCard(
    String label,
    DateTime? time,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formatTime(DateTime? dt) {
      if (dt == null) return '--:--';
      return DateFormat.jm().format(dt.toLocal());
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatTime(time),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final employeeId = user?.employeeId ?? '';

    final attendance = Provider.of<AttendanceProvider>(context);
    final holidays = Provider.of<HolidayProvider>(context);

    // Using optimized employee-specific data
    final dateWiseData = attendance.getEmployeeDateWiseData(employeeId);
    final holidayList = holidays.holidays;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            pinned: true,
            toolbarHeight: 50,
            centerTitle: true,
            title: Text(
              'Attendance',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCalendar(dateWiseData, holidayList),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _selectedDay != null
                  ? _buildDayDetails(_selectedDay!)
                  : const SizedBox(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCalendarLegend(),
            ),
          ), // Extra padding for nav bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ), // Extra padding for nav bar
        ],
      ),
    );
  }
}
