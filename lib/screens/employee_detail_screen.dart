import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/screens/edit_employee_screen.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';
import 'package:quantum_dashboard/utils/string_extensions.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timeline_tile/timeline_tile.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeDetailScreen({Key? key, required this.employee})
    : super(key: key);

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Employee _employee;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Attendance>> _events = {};
  Map<DateTime, Holiday> _holidays = {};
  bool _isLoadingCalendarData = false;

  Future<void> _refreshEmployee() async {
    if (!mounted) return;
    final emp = await context.read<EmployeeProvider>().getEmployee(_employee.employeeId);
    if (emp != null && mounted) {
      setState(() => _employee = emp);
    }
  }

  @override
  void initState() {
    super.initState();
    _employee = widget.employee;
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceForCalendar();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceForCalendar() async {
    if (!mounted) return;

    setState(() {
      _isLoadingCalendarData = true;
      // Clear old events to prevent showing past month data
      _events = {};
      _holidays = {};
    });

    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final holidayProvider = context.read<HolidayProvider>();

      final focusedMonth = _focusedDay.month;
      final focusedYear = _focusedDay.year;

      // Clear cache for this month to force refresh
      attendanceProvider.clearDateWiseCache(
        _employee.employeeId,
        month: focusedMonth,
        year: focusedYear,
      );

      final leaveProvider = context.read<LeaveProvider>();

      await Future.wait([
        attendanceProvider.getDateWiseData(
          _employee.employeeId,
          month: focusedMonth,
          year: focusedYear,
          forceRefresh: true,
        ),
        attendanceProvider.getPunches(
          _employee.employeeId,
          month: focusedMonth,
          year: focusedYear,
          forceRefresh: true,
        ),
        holidayProvider.getHolidaysByYear(focusedYear),
        leaveProvider.getMyLeaves(_employee.employeeId),
      ]);

      final Map<DateTime, List<Attendance>> events = {};

      // Build events from punches
      for (var attendance in attendanceProvider.punches) {
        final date = DateTime(
          attendance.punchIn.year,
          attendance.punchIn.month,
          attendance.punchIn.day,
        );
        if (!events.containsKey(date)) {
          events[date] = [];
        }
        events[date]!.add(attendance);
      }

      // Also add events from dateWiseData for dates that might not have punches
      final employeeDateWiseData = attendanceProvider.getEmployeeDateWiseData(
        _employee.employeeId,
      );
      for (var data in employeeDateWiseData) {
        try {
          final dateKey = data['_id'] as String?;
          if (dateKey != null) {
            // Parse date from key format: "DD-MM-YYYY"
            final parts = dateKey.split('-');
            if (parts.length == 3) {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              final date = DateTime(year, month, day);
              if (!events.containsKey(date)) {
                events[date] = [];
              }
            }
          }
        } catch (e) {
          print('Error parsing date from dateWiseData: $e');
        }
      }

      final Map<DateTime, Holiday> holidays = {};
      for (var holiday in holidayProvider.holidays) {
        final date = DateTime(
          holiday.date.year,
          holiday.date.month,
          holiday.date.day,
        );
        holidays[date] = holiday;
      }

      if (mounted) {
        setState(() {
          _events = events;
          _holidays = holidays;
          _isLoadingCalendarData = false;
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
      if (mounted) {
        setState(() {
          _isLoadingCalendarData = false;
        });
      }
    }
  }

  List<Attendance> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  Leave? _getLeaveForDay(DateTime day) {
    final leaveProvider = context.read<LeaveProvider>();
    return _getLeaveForDate(day, leaveProvider.leaves);
  }

  Holiday? _getHolidayForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _holidays[date];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'halfday':
      case 'half day':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'holiday':
        return Colors.purple;
      case 'weekend':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _buildAppBarTitle(colorScheme),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.edit_square),
              tooltip: 'Edit employee',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditEmployeeScreen(
                      employee: _employee,
                      onEmployeeUpdated: _refreshEmployee,
                    ),
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.7),
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Details',),
            Tab(icon: Icon(Icons.calendar_today), text: 'Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(colorScheme, theme),
          _buildAttendanceTab(colorScheme, theme),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(ColorScheme colorScheme, ThemeData theme) {
    final padding = MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0;
    return RefreshIndicator(
      onRefresh: _refreshEmployee,
      color: colorScheme.primary,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Personal Information
          _buildSectionCard(
            context: context,
            title: 'Personal Information',
            icon: Icons.person_outline,
            colorScheme: colorScheme,
            children: [
              _buildInfoRow(
                icon: Icons.person,
                label: 'Full Name',
                value: _employee.fullName,
                colorScheme: colorScheme,
              ),
              _buildInfoRow(
                icon: Icons.badge,
                label: 'Employee ID',
                value: _employee.employeeId,
                colorScheme: colorScheme,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'First Name',
                value: _employee.firstName,
                colorScheme: colorScheme,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Last Name',
                value: _employee.lastName,
                colorScheme: colorScheme,
              ),
              if (_employee.gender != null)
                _buildInfoRow(
                  icon: Icons.wc,
                  label: 'Gender',
                  value: _employee.gender!,
                  colorScheme: colorScheme,
                ),
              _buildInfoRow(
                icon: Icons.cake,
                label: 'Date of Birth',
                value: DateFormat('dd MMMM yyyy').format(_employee.dateOfBirth),
                colorScheme: colorScheme,
                isLast: _employee.fathername == null,
              ),
              if (_employee.fathername != null)
                _buildInfoRow(
                  icon: Icons.family_restroom,
                  label: 'Father\'s Name',
                  value: _employee.fathername!,
                  colorScheme: colorScheme,
                  isLast: true,
                ),
            ],
          ),
          SizedBox(height: 16),

          // Work Information
          _buildSectionCard(
            context: context,
            title: 'Work Information',
            icon: Icons.work_outline,
            colorScheme: colorScheme,
            children: [
              if (_employee.department != null)
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Department',
                  value: _employee.department!,
                  colorScheme: colorScheme,
                ),
              if (_employee.designation != null)
                _buildInfoRow(
                  icon: Icons.stars,
                  label: 'Designation',
                  value: _employee.designation!,
                  colorScheme: colorScheme,
                ),
              if (_employee.grade != null)
                _buildInfoRow(
                  icon: Icons.grade,
                  label: 'Grade',
                  value: _employee.grade!,
                  colorScheme: colorScheme,
                ),
              if (_employee.role != null)
                _buildInfoRow(
                  icon: Icons.admin_panel_settings,
                  label: 'Role',
                  value: _employee.role!,
                  colorScheme: colorScheme,
                ),
              if (_employee.report != null)
                _buildInfoRow(
                  icon: Icons.supervisor_account,
                  label: 'Reports To',
                  value: _employee.report!,
                  colorScheme: colorScheme,
                ),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Joining Date',
                value: DateFormat('dd MMMM yyyy').format(_employee.joiningDate),
                colorScheme: colorScheme,
                isLast: true,
              ),
            ],
          ),
          SizedBox(height: 16),

          // Contact Information
          _buildSectionCard(
            context: context,
            title: 'Contact Information',
            icon: Icons.contact_phone,
            colorScheme: colorScheme,
            children: [
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: _employee.email,
                colorScheme: colorScheme,
                copyable: true,
              ),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Mobile',
                value: _employee.mobile,
                colorScheme: colorScheme,
                copyable: true,
                isLast: _employee.address == null,
              ),
              if (_employee.address != null)
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: _employee.address!,
                  colorScheme: colorScheme,
                  isLast: true,
                ),
            ],
          ),
          SizedBox(height: 16),

          // Banking Information (if available)
          if (_employee.bankname != null ||
              _employee.accountnumber != null ||
              _employee.ifsccode != null)
            _buildSectionCard(
              context: context,
              title: 'Banking Information',
              icon: Icons.account_balance,
              colorScheme: colorScheme,
              children: [
                if (_employee.bankname != null)
                  _buildInfoRow(
                    icon: Icons.account_balance,
                    label: 'Bank Name',
                    value: _employee.bankname!,
                    colorScheme: colorScheme,
                    isLast: _employee.accountnumber == null && _employee.ifsccode == null,
                  ),
                if (_employee.accountnumber != null)
                  _buildInfoRow(
                    icon: Icons.account_box,
                    label: 'Account Number',
                    value: _employee.accountnumber!,
                    colorScheme: colorScheme,
                    isLast: _employee.ifsccode == null,
                  ),
                if (_employee.ifsccode != null)
                  _buildInfoRow(
                    icon: Icons.code,
                    label: 'IFSC Code',
                    value: _employee.ifsccode!,
                    colorScheme: colorScheme,
                    isLast: true,
                  ),
              ],
            ),
          SizedBox(height: 16),

          // Government Information (if available)
          if (_employee.PANno != null ||
              _employee.UANno != null ||
              _employee.ESIno != null)
            _buildSectionCard(
              context: context,
              title: 'Government Information',
              icon: Icons.description,
              colorScheme: colorScheme,
              children: [
                if (_employee.PANno != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'PAN Number',
                    value: _employee.PANno!,
                    colorScheme: colorScheme,
                    isLast: _employee.UANno == null && _employee.ESIno == null,
                  ),
                if (_employee.UANno != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'UAN Number',
                    value: _employee.UANno!,
                    colorScheme: colorScheme,
                    isLast: _employee.ESIno == null,
                  ),
                if (_employee.ESIno != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'ESI Number',
                    value: _employee.ESIno!,
                    colorScheme: colorScheme,
                    isLast: true,
                  ),
              ],
            ),
          SizedBox(height: 32),
        ],
      ),
    ),
    );
  }

  Widget _buildAttendanceTab(ColorScheme colorScheme, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Widget
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF7F9FC), Color(0xFFFFFFFF)],
                    ),
              color: isDark ? colorScheme.surfaceContainerHighest : null,
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
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                if (_isLoadingCalendarData)
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Loading attendance data...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) async {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // Show bottom sheet with punching logs stepper
                    final attendanceProvider = context
                        .read<AttendanceProvider>();
                    final holidayProvider = context.read<HolidayProvider>();
                    final dateWiseData = attendanceProvider
                        .getEmployeeDateWiseData(_employee.employeeId);
                    final holidayList = holidayProvider.holidays;

                    // Format date as YYYY-MM-DD for the API
                    final dateString =
                        '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';

                    // Fetch punches for the specific date
                    List<dynamic> punches = [];
                    double workingHours = 0.0;
                    double breakHours = 0.0;
                    DateTime? firstPunchIn;
                    DateTime? lastPunchOut;

                    try {
                      final punchData = await attendanceProvider
                          .getEmployeeDatePunches(
                            _employee.employeeId,
                            dateString,
                          );

                      // Convert Attendance objects to maps for the stepper
                      final attendanceList =
                          punchData['punches'] as List<Attendance>? ?? [];
                      punches = attendanceList.map((attendance) {
                        return {
                          'punchIn': attendance.punchIn.toIso8601String(),
                          'punchOut': attendance.punchOut?.toIso8601String(),
                          'duration': attendance.totalWorkingTime,
                          'breakTime': attendance.breakTime,
                        };
                      }).toList();

                      workingHours =
                          (punchData['totalWorkingTime'] ?? 0.0) / 3600.0;

                      // Calculate total break time
                      breakHours = attendanceList.fold<double>(
                        0.0,
                        (sum, attendance) =>
                            sum + (attendance.breakTime / 3600.0),
                      );

                      // Get first punch in and last punch out
                      if (attendanceList.isNotEmpty) {
                        final sortedByPunchIn = List<Attendance>.from(
                          attendanceList,
                        )..sort((a, b) => a.punchIn.compareTo(b.punchIn));
                        firstPunchIn = sortedByPunchIn.first.punchIn;

                        final sortedByPunchOut =
                            attendanceList
                                .where((a) => a.punchOut != null)
                                .toList()
                              ..sort(
                                (a, b) => a.punchOut!.compareTo(b.punchOut!),
                              );
                        if (sortedByPunchOut.isNotEmpty) {
                          lastPunchOut = sortedByPunchOut.last.punchOut;
                        }
                      }
                    } catch (e) {
                      print('Error fetching punches for date: $e');
                    }

                    // Get status from dateWiseData
                    // Get status
                    final status = _getAttendanceStatus(
                      selectedDay,
                      dateWiseData,
                      holidayList.firstWhere(
                        (h) => isSameDay(h.date, selectedDay),
                        orElse: () => Holiday(
                          id: '',
                          title: '',
                          date: DateTime.now(),
                          day: '',
                          action: '',
                        ),
                      ),
                    );
                    final color = _getStatusColor(status);
                    final icon = _getStatusIcon(status);

                    // Check for holiday
                    final holiday = holidayList.firstWhere(
                      (h) => isSameDay(h.date, selectedDay),
                      orElse: () => Holiday(
                        id: '',
                        title: '',
                        date: DateTime.now(),
                        day: '',
                        action: '',
                      ),
                    );

                    // Check for leave
                    final leaveProvider = context.read<LeaveProvider>();
                    final leave = _getLeaveForDate(
                      selectedDay,
                      leaveProvider.leaves,
                    );

                    if (!mounted) return;

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      enableDrag: true,
                      isDismissible: true,
                      // showDragHandle: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.7,
                        minChildSize: 0.3,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) =>
                            _buildPunchingLogsBottomSheet(
                              context,
                              scrollController,
                              selectedDay,
                              status,
                              color,
                              icon,
                              workingHours,
                              breakHours,
                              firstPunchIn,
                              lastPunchOut,
                              punches,
                              holiday,
                              leave,
                            ),
                      ),
                    );
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
                    _loadAttendanceForCalendar();
                  },
                  eventLoader: _getEventsForDay,
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
                    defaultDecoration: BoxDecoration(shape: BoxShape.circle),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: colorScheme.onSurface,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
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
                              color: _getStatusColor(
                                attendance.attendanceStatus.toLowerCase(),
                              ),
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
                SizedBox(height: 20),
                _buildCalendarLegend(colorScheme),
              ],
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final holiday = _getHolidayForDay(date);
    final leave = _getLeaveForDay(date);

    // Get status from dateWiseData similar to new_calender_screen.dart
    final attendanceProvider = context.read<AttendanceProvider>();
    final dateWiseData = attendanceProvider.getEmployeeDateWiseData(
      _employee.employeeId,
    );
    final status = _getAttendanceStatus(date, dateWiseData, holiday);

    Color backgroundColor = Colors.transparent;
    Color textColor = colorScheme.onSurface;
    List<BoxShadow>? shadows;

    // Check for holiday first (highest priority)
    if (holiday != null) {
      final holidayColor = _getStatusColor('holiday');
      backgroundColor = isDark
          ? holidayColor.withOpacity(0.25)
          : holidayColor.withOpacity(0.2);
      textColor = isDark
          ? holidayColor.withOpacity(0.9)
          : _getDarkerShade(holidayColor);
      shadows = [
        BoxShadow(
          color: holidayColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    // Then check for leave (second priority)
    else if (leave != null) {
      final leaveColor = Colors.blue;
      backgroundColor = isDark
          ? leaveColor.withOpacity(0.25)
          : leaveColor.withOpacity(0.2);
      textColor = isDark
          ? leaveColor.withOpacity(0.9)
          : _getDarkerShade(leaveColor);
      shadows = [
        BoxShadow(
          color: leaveColor.withOpacity(0.3),
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
      textColor = isDark
          ? colorScheme.onSurface.withOpacity(0.6)
          : _getDarkerShade(weekendColor);
    } else if (status.isNotEmpty) {
      final statusColor = _getStatusColor(status);
      backgroundColor = isDark
          ? statusColor.withOpacity(0.25)
          : statusColor.withOpacity(0.2);
      textColor = isDark
          ? statusColor.withOpacity(0.9)
          : _getDarkerShade(statusColor);
      shadows = [
        BoxShadow(
          color: statusColor.withOpacity(0.3),
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
      backgroundColor = colorScheme.primary;
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.5),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ];
    } else if (isToday) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
      shadows = [
        BoxShadow(
          color: Colors.orange.withOpacity(0.5),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 2,
        ),
      ];
    }

    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: shadows,
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: isSelected || isToday
                ? FontWeight.bold
                : FontWeight.w600,
            fontSize: 14,
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
      ),
    );
  }

  Leave? _getLeaveForDate(DateTime date, List<Leave> leaves) {
    final selectedDate = DateTime(date.year, date.month, date.day);
    for (var leave in leaves) {
      final fromDate = DateTime(
        leave.from.year,
        leave.from.month,
        leave.from.day,
      );
      final toDate = DateTime(leave.to.year, leave.to.month, leave.to.day);
      if (selectedDate.isAtSameMomentAs(fromDate) ||
          selectedDate.isAtSameMomentAs(toDate) ||
          (selectedDate.isAfter(fromDate) && selectedDate.isBefore(toDate))) {
        return leave;
      }
    }
    return null;
  }

  String _getAttendanceStatus(
    DateTime date,
    List<Map<String, dynamic>> dateWiseData,
    Holiday? holiday,
  ) {
    final key =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final day = dateWiseData.firstWhere(
      (d) => d['_id'] == key,
      orElse: () => {},
    );

    // Check for holiday first (only if it's actually a holiday)
    if (holiday != null && holiday.id.isNotEmpty) {
      return 'Holiday';
    }

    // Check for weekend
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      if (day.isEmpty) {
        return 'Weekend';
      }
    }

    // First, check if backend provides a status field directly
    if (day.containsKey('status') && day['status'] != null) {
      final backendStatus = day['status'].toString().trim();
      if (backendStatus.isNotEmpty && backendStatus.toLowerCase() != 'null') {
        // Normalize status: capitalize first letter of each word
        final words = backendStatus.toLowerCase().split(' ');
        final normalizedStatus = words
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
        return normalizedStatus;
      }
    }

    // Fallback: Calculate status from working hours if no status provided
    if (day.containsKey('totalWorkingTime')) {
      final workingHours =
          ((day['totalWorkingTime'] ?? 0.0) as num).toDouble() / 3600.0;

      // Present: >= 7.5 hours (7h 30m)
      if (workingHours >= 7.5) {
        return 'Present';
      }

      // Half Day: >= 3.5 hours (3h 30m) but < 7.5 hours
      if (workingHours >= 3.5) {
        return 'Half Day';
      }

      // Less than 3.5 hours: Mark as Absent for past dates
      if (workingHours > 0) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (date.isBefore(today)) {
          return 'Absent';
        }
      }
    }

    // Only mark as absent if it's a past weekday
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today) &&
        date.weekday != DateTime.saturday &&
        date.weekday != DateTime.sunday) {
      return 'Absent';
    }

    // Future dates or current day with no data
    return '';
  }

  Color _getDarkerShade(Color color) {
    return Color.fromRGBO(
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
      1.0,
    );
  }

  Widget _buildCalendarLegend(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Present', Colors.green, colorScheme, isDark),
              _buildLegendItem('Half Day', Colors.orange, colorScheme, isDark),
              _buildLegendItem('Absent', Colors.red, colorScheme, isDark),
              _buildLegendItem('Holiday', Colors.purple, colorScheme, isDark),
              _buildLegendItem('Weekend', Colors.grey, colorScheme, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    String label,
    Color color,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final dotColor = isDark ? color.withOpacity(0.8) : color;
    final labelColor = isDark ? colorScheme.onSurface : Colors.grey[700];

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
        Icon(_getStatusIcon(label), size: 16, color: dotColor),
        SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'halfday':
      case 'half day':
        return Icons.schedule;
      case 'absent':
        return Icons.cancel;
      case 'holiday':
        return Icons.celebration;
      case 'weekend':
        return Icons.weekend;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildAppBarTitle(ColorScheme colorScheme) {
    return Row(
      children: [
        _buildCompactAvatar(_employee),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _employee.fullName.toTitleCase(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAvatar(Employee employee) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.white.withOpacity(0.3),
      child: _buildProfileImage(employee, 40),
    );
  }

  Widget _buildProfileImage(Employee employee, [double size = 80]) {
    if (employee.profileImage.isNotEmpty) {
      // Handle base64 data URL
      if (employee.profileImage.startsWith('data:image')) {
        try {
          final String base64String = employee.profileImage.split(',').last;
          final bytes = base64Decode(base64String);
          return ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderAvatar(employee.firstName, size);
              },
            ),
          );
        } catch (e) {
          return _buildPlaceholderAvatar(employee.firstName, size);
        }
      }
      // Handle network URL
      else {
        try {
          final uri = Uri.tryParse(employee.profileImage);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            return ClipOval(
              child: Image.network(
                employee.profileImage,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderAvatar(employee.firstName, size);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderAvatar(employee.firstName, size);
                },
              ),
            );
          }
        } catch (e) {
          // Fall through to placeholder
        }
      }
    }
    return _buildPlaceholderAvatar(employee.firstName, size);
  }

  Widget _buildPlaceholderAvatar(String firstName, [double size = 80]) {
    if (firstName.isEmpty) firstName = '?';
    return Center(
      child: Text(
        firstName.substring(0, 1).toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              SizedBox(width: 14),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    bool copyable = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(Icons.copy_outlined, size: 20),
              color: colorScheme.primary,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary.withOpacity(0.08),
                minimumSize: Size(36, 36),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                SnackbarUtils.showSuccess(context, '$label copied to clipboard');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPunchingLogsBottomSheet(
    BuildContext context,
    ScrollController scrollController,
    DateTime date,
    String status,
    Color color,
    IconData icon,
    double workingHours,
    double breakHours,
    DateTime? firstPunchIn,
    DateTime? lastPunchOut,
    List<dynamic> punches,
    Holiday holiday,
    Leave? leave,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
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
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
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

                // Holiday info (expanded when replacing logs)
                if (holiday.id.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.celebration,
                                  color: Colors.purple,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
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
                                    SizedBox(height: 4),
                                    Text(
                                      holiday.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Divider(color: Colors.purple.withOpacity(0.2)),
                          SizedBox(height: 12),
                          // Date
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Date: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(holiday.date),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (holiday.day.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 18,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Day: ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                                Text(
                                  holiday.day,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                // Leave info (expanded when replacing logs)
                if (leave != null) ...[
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event_busy,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'On Leave',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      leave.type,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Divider(color: Colors.blue.withOpacity(0.2)),
                          SizedBox(height: 12),
                          // Date Range
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'From: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(leave.from),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'To: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, yyyy').format(leave.to),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // Days
                          Row(
                            children: [
                              Icon(
                                Icons.today,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Duration: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                '${leave.days} ${leave.days == 1 ? 'day' : 'days'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (leave.reason.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Divider(color: Colors.blue.withOpacity(0.2)),
                            SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 18,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reason',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        leave.reason,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: 12),
                          Divider(color: Colors.blue.withOpacity(0.2)),
                          SizedBox(height: 12),
                          // Status
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Status: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      leave.status.toLowerCase() == 'approved'
                                      ? Colors.green.withOpacity(0.1)
                                      : leave.status.toLowerCase() == 'pending'
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        leave.status.toLowerCase() == 'approved'
                                        ? Colors.green.withOpacity(0.3)
                                        : leave.status.toLowerCase() ==
                                              'pending'
                                        ? Colors.orange.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  leave.status,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        leave.status.toLowerCase() == 'approved'
                                        ? Colors.green[800]
                                        : leave.status.toLowerCase() ==
                                              'pending'
                                        ? Colors.orange[800]
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Summary Boxes (only show if no leave and no holiday)
                if (leave == null &&
                    holiday.id.isEmpty &&
                    (firstPunchIn != null ||
                        lastPunchOut != null ||
                        workingHours > 0 ||
                        breakHours > 0)) ...[
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // First Punch In Box
                          if (firstPunchIn != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.login,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Punch In',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(firstPunchIn.toLocal()),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          // Last Punch Out Box
                          if (lastPunchOut != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Punch Out',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(lastPunchOut.toLocal()),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          // Working Hours Box
                          if (workingHours > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Work Time',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _formatHours(workingHours),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          if (workingHours > 0 && breakHours > 0)
                            SizedBox(width: 12),
                          // Break Hours Box
                          if (breakHours > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pause_circle_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Break Time',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _formatHours(breakHours),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Punching Logs Section with Stepper Pattern (only show if no leave and no holiday)
                if (leave == null && holiday.id.isEmpty) ...[
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Punching Logs',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      // constraints: BoxConstraints(maxHeight: 400),
                      child: _buildPunchingStepper(punches, colorScheme),
                    ),
                  ),

                  // Empty state if no punches
                  if (punches.isEmpty &&
                      firstPunchIn == null &&
                      lastPunchOut == null)
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 48,
                            color: colorScheme.onSurface.withOpacity(0.3),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No punching logs for this day',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPunchingStepper(List<dynamic> punches, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Debug: Print punches data
    print('🔍 Building stepper with ${punches.length} punches');
    print('🔍 Punches data: $punches');

    // Extract all punch events (both ins and outs) and sort chronologically
    List<Map<String, dynamic>> timelineEvents = [];
    for (var punch in punches) {
      try {
        // Check if punch is a Map
        if (punch is Map) {
          // Add punch in event
          if (punch['punchIn'] != null) {
            final punchIn = DateTime.parse(punch['punchIn'].toString());
            timelineEvents.add({
              'type': 'punchIn',
              'time': punchIn,
              'label': 'Punch In',
            });
          }
          // Add punch out event if exists
          if (punch['punchOut'] != null) {
            final punchOut = DateTime.parse(punch['punchOut'].toString());
            timelineEvents.add({
              'type': 'punchOut',
              'time': punchOut,
              'label': 'Punch Out',
            });
          }
        }
      } catch (e) {
        print('❌ Error parsing punch event: $e');
        print('❌ Punch data: $punch');
      }
    }

    // Sort events chronologically
    timelineEvents.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );

    print('🔍 Extracted ${timelineEvents.length} events from punches');

    if (timelineEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No activities yet.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Column(
      children: timelineEvents.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isFirst = index == 0;
        final isLast = index == timelineEvents.length - 1;
        final isPunchIn = event['type'] == 'punchIn';

        return TimelineTile(
          alignment: TimelineAlign.start,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 20,
            height: 20,
            indicator: Container(
              decoration: BoxDecoration(
                color: isPunchIn
                    ? (isDark
                          ? colorScheme.primary.withOpacity(0.3)
                          : colorScheme.primary.withOpacity(0.2))
                    : colorScheme.primary,
                shape: BoxShape.circle,
                border: isPunchIn
                    ? Border.all(color: colorScheme.primary, width: 3)
                    : null,
              ),
            ),
          ),
          beforeLineStyle: LineStyle(
            color: isDark
                ? colorScheme.outline.withOpacity(0.3)
                : colorScheme.outline,
            thickness: 2,
          ),
          endChild: Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['label'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat.jm().format((event['time'] as DateTime).toLocal()),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).floor();
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
