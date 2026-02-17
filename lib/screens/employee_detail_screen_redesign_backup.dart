import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';

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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Attendance>> _events = {};
  bool _isLoadingCalendarData = false;

  @override
  void initState() {
    super.initState();
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
    });

    try {
      final attendanceProvider = context.read<AttendanceProvider>();
      final holidayProvider = context.read<HolidayProvider>();

      final focusedMonth = _focusedDay.month;
      final focusedYear = _focusedDay.year;

      // Clear cache for this month to force refresh
      attendanceProvider.clearDateWiseCache(
        widget.employee.employeeId,
        month: focusedMonth,
        year: focusedYear,
      );

      final leaveProvider = context.read<LeaveProvider>();

      await Future.wait([
        attendanceProvider.getDateWiseData(
          widget.employee.employeeId,
          month: focusedMonth,
          year: focusedYear,
          forceRefresh: true,
        ),
        attendanceProvider.getPunches(
          widget.employee.employeeId,
          month: focusedMonth,
          year: focusedYear,
          forceRefresh: true,
        ),
        holidayProvider.getHolidaysByYear(focusedYear),
        leaveProvider.getMyLeaves(widget.employee.employeeId),
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
        widget.employee.employeeId,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                  StretchMode.fadeTitle,
                ],
                centerTitle: true,
                title: Text(
                  widget.employee.fullName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image or Gradient
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary,
                            colorScheme.primary.withOpacity(0.8),
                            colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
                    // Centered Profile Image with Glassmorphism-like card
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag:
                                  'employee_avatar_${widget.employee.employeeId}',
                              child: _buildProfileAvatar(
                                widget.employee,
                                colorScheme,
                                radius: 60,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          if (widget.employee.designation != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.employee.designation!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 3,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  indicatorPadding: EdgeInsets.symmetric(horizontal: 16),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Attendance',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                theme.scaffoldBackgroundColor,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(colorScheme, theme),
            _buildAttendanceTab(colorScheme, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(ColorScheme colorScheme, ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(widget.employee, colorScheme),
          SizedBox(height: 24),

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
                value: widget.employee.fullName,
                colorScheme: colorScheme,
              ),
              _buildInfoRow(
                icon: Icons.badge,
                label: 'Employee ID',
                value: widget.employee.employeeId,
                colorScheme: colorScheme,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'First Name',
                value: widget.employee.firstName,
                colorScheme: colorScheme,
              ),
              _buildInfoRow(
                icon: Icons.person_outline,
                label: 'Last Name',
                value: widget.employee.lastName,
                colorScheme: colorScheme,
              ),
              if (widget.employee.gender != null)
                _buildInfoRow(
                  icon: Icons.wc,
                  label: 'Gender',
                  value: widget.employee.gender!,
                  colorScheme: colorScheme,
                ),
              _buildInfoRow(
                icon: Icons.cake,
                label: 'Date of Birth',
                value: DateFormat(
                  'dd MMMM yyyy',
                ).format(widget.employee.dateOfBirth),
                colorScheme: colorScheme,
              ),
              if (widget.employee.fathername != null)
                _buildInfoRow(
                  icon: Icons.family_restroom,
                  label: 'Father\'s Name',
                  value: widget.employee.fathername!,
                  colorScheme: colorScheme,
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
              if (widget.employee.department != null)
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'Department',
                  value: widget.employee.department!,
                  colorScheme: colorScheme,
                ),
              if (widget.employee.designation != null)
                _buildInfoRow(
                  icon: Icons.stars,
                  label: 'Designation',
                  value: widget.employee.designation!,
                  colorScheme: colorScheme,
                ),
              if (widget.employee.grade != null)
                _buildInfoRow(
                  icon: Icons.grade,
                  label: 'Grade',
                  value: widget.employee.grade!,
                  colorScheme: colorScheme,
                ),
              if (widget.employee.role != null)
                _buildInfoRow(
                  icon: Icons.admin_panel_settings,
                  label: 'Role',
                  value: widget.employee.role!,
                  colorScheme: colorScheme,
                ),
              if (widget.employee.report != null)
                _buildInfoRow(
                  icon: Icons.supervisor_account,
                  label: 'Reports To',
                  value: widget.employee.report!,
                  colorScheme: colorScheme,
                ),
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Joining Date',
                value: DateFormat(
                  'dd MMMM yyyy',
                ).format(widget.employee.joiningDate),
                colorScheme: colorScheme,
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
                value: widget.employee.email,
                colorScheme: colorScheme,
                copyable: true,
              ),
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Mobile',
                value: widget.employee.mobile,
                colorScheme: colorScheme,
                copyable: true,
              ),
              if (widget.employee.address != null)
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: widget.employee.address!,
                  colorScheme: colorScheme,
                ),
            ],
          ),
          SizedBox(height: 16),

          // Banking Information (if available)
          if (widget.employee.bankname != null ||
              widget.employee.accountnumber != null ||
              widget.employee.ifsccode != null)
            _buildSectionCard(
              context: context,
              title: 'Banking Information',
              icon: Icons.account_balance,
              colorScheme: colorScheme,
              children: [
                if (widget.employee.bankname != null)
                  _buildInfoRow(
                    icon: Icons.account_balance,
                    label: 'Bank Name',
                    value: widget.employee.bankname!,
                    colorScheme: colorScheme,
                  ),
                if (widget.employee.accountnumber != null)
                  _buildInfoRow(
                    icon: Icons.account_box,
                    label: 'Account Number',
                    value: widget.employee.accountnumber!,
                    colorScheme: colorScheme,
                  ),
                if (widget.employee.ifsccode != null)
                  _buildInfoRow(
                    icon: Icons.code,
                    label: 'IFSC Code',
                    value: widget.employee.ifsccode!,
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          SizedBox(height: 16),

          // Government Information (if available)
          if (widget.employee.PANno != null ||
              widget.employee.UANno != null ||
              widget.employee.ESIno != null)
            _buildSectionCard(
              context: context,
              title: 'Government Information',
              icon: Icons.description,
              colorScheme: colorScheme,
              children: [
                if (widget.employee.PANno != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'PAN Number',
                    value: widget.employee.PANno!,
                    colorScheme: colorScheme,
                  ),
                if (widget.employee.UANno != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'UAN Number',
                    value: widget.employee.UANno!,
                    colorScheme: colorScheme,
                  ),
                if (widget.employee.ESIno != null)
                  _buildInfoRow(
                    icon: Icons.badge,
                    label: 'ESI Number',
                    value: widget.employee.ESIno!,
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab(ColorScheme colorScheme, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Widget
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: colorScheme.outline.withOpacity(isDark ? 0.1 : 0.05),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isLoadingCalendarData)
                  Container(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Updating calendar...',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.6),
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
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  rowHeight: 52,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) async {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    // The original massive block of logic for fetching punches and showing bottom sheet remains here
                    // I'll keep the logic but the bottom sheet will be styled by my refactored _buildPunchingLogsBottomSheet

                    final attendanceProvider = context
                        .read<AttendanceProvider>();
                    final holidayProvider = context.read<HolidayProvider>();
                    final dateWiseData = attendanceProvider
                        .getEmployeeDateWiseData(widget.employee.employeeId);
                    final holidayList = holidayProvider.holidays;

                    final dateString =
                        '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';

                    List<dynamic> punches = [];
                    double workingHours = 0.0;
                    double breakHours = 0.0;
                    DateTime? firstPunchIn;
                    DateTime? lastPunchOut;

                    try {
                      final punchData = await attendanceProvider
                          .getEmployeeDatePunches(
                            widget.employee.employeeId,
                            dateString,
                          );

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
                      breakHours = attendanceList.fold<double>(
                        0.0,
                        (sum, attendance) =>
                            sum + (attendance.breakTime / 3600.0),
                      );

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
                        if (sortedByPunchOut.isNotEmpty)
                          lastPunchOut = sortedByPunchOut.last.punchOut;
                      }
                    } catch (e) {
                      print('Error fetching punches: $e');
                    }

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
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.7,
                        minChildSize: 0.4,
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
                  onFormatChanged: (format) =>
                      setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) {
                    setState(() => _focusedDay = focusedDay);
                    _loadAttendanceForCalendar();
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(
                      color: Colors.red.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: colorScheme.primary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.primary,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) =>
                        _buildCalendarDay(date),
                    selectedBuilder: (context, date, _) =>
                        _buildCalendarDay(date, isSelected: true),
                    todayBuilder: (context, date, _) =>
                        _buildCalendarDay(date, isToday: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(color: colorScheme.outline.withOpacity(0.08)),
                ),
                _buildCalendarLegend(colorScheme),
              ],
            ),
          ),
          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(
    DateTime date, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final attendanceProvider = context.read<AttendanceProvider>();
    final holidayProvider = context.read<HolidayProvider>();
    final leaveProvider = context.read<LeaveProvider>();

    final dateWiseData = attendanceProvider.getEmployeeDateWiseData(
      widget.employee.employeeId,
    );
    final holidayList = holidayProvider.holidays;
    final status = _getAttendanceStatus(
      date,
      dateWiseData,
      holidayList.firstWhere(
        (h) => isSameDay(h.date, date),
        orElse: () => Holiday(
          id: '',
          title: '',
          date: DateTime.now(),
          day: '',
          action: '',
        ),
      ),
    );
    final leave = _getLeaveForDate(date, leaveProvider.leaves);
    final statusColor = leave != null ? Colors.blue : _getStatusColor(status);

    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : isToday
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${date.day}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected || isToday
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isToday
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (statusColor != Colors.transparent && !isSelected)
            Positioned(
              bottom: 6,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
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

  Widget _buildCalendarLegend(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Legend',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _buildLegendItem('Present', Colors.green, colorScheme),
            _buildLegendItem('Half Day', Colors.orange, colorScheme),
            _buildLegendItem('Absent', Colors.red, colorScheme),
            _buildLegendItem('Holiday', Colors.purple, colorScheme),
            _buildLegendItem('Weekend', Colors.grey, colorScheme),
            _buildLegendItem('Leave', Colors.blue, colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  Widget _buildHeaderCard(Employee employee, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          _buildProfileAvatar(employee, colorScheme),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                if (employee.designation != null)
                  Text(
                    employee.designation!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                SizedBox(height: 8),
                Text(
                  employee.employeeId,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
    Employee employee,
    ColorScheme colorScheme, {
    double radius = 40,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withOpacity(0.2),
      child: _buildProfileImage(employee, radius: radius),
    );
  }

  Widget _buildProfileImage(Employee employee, {double radius = 40}) {
    double size = radius * 2;
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
                return _buildPlaceholderAvatar(employee.firstName, size: size);
              },
            ),
          );
        } catch (e) {
          return _buildPlaceholderAvatar(employee.firstName, size: size);
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
                  return _buildPlaceholderAvatar(
                    employee.firstName,
                    size: size,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderAvatar(
                    employee.firstName,
                    size: size,
                  );
                },
              ),
            );
          }
        } catch (e) {
          // Fall through to placeholder
        }
      }
    }
    return _buildPlaceholderAvatar(employee.firstName, size: size);
  }

  Widget _buildPlaceholderAvatar(String firstName, {double size = 80}) {
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(isDark ? 0.1 : 0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 22),
                ),
                SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outline.withOpacity(0.08),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(children: children),
          ),
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
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
            ),
            child: Icon(
              icon,
              size: 18,
              color: colorScheme.primary.withOpacity(0.8),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implement copy to clipboard
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.copy_all_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
              ),
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

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy').format(date),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 16, color: color),
                            SizedBox(width: 8),
                            Text(
                              status.isEmpty ? 'N/A' : status,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Summary Grid
                  if (leave == null && holiday.id.isEmpty)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                      children: [
                        _buildSummaryBox(
                          'PUNCH IN',
                          firstPunchIn != null
                              ? DateFormat(
                                  'h:mm a',
                                ).format(firstPunchIn.toLocal())
                              : '--:--',
                          Icons.login_rounded,
                          Colors.green,
                          colorScheme,
                        ),
                        _buildSummaryBox(
                          'PUNCH OUT',
                          lastPunchOut != null
                              ? DateFormat(
                                  'h:mm a',
                                ).format(lastPunchOut.toLocal())
                              : '--:--',
                          Icons.logout_rounded,
                          Colors.orange,
                          colorScheme,
                        ),
                        _buildSummaryBox(
                          'WORK TIME',
                          _formatHours(workingHours),
                          Icons.schedule_rounded,
                          colorScheme.primary,
                          colorScheme,
                        ),
                        _buildSummaryBox(
                          'BREAK TIME',
                          _formatHours(breakHours),
                          Icons.coffee_rounded,
                          Colors.blue,
                          colorScheme,
                        ),
                      ],
                    ),

                  // Holiday / Leave Information
                  if (holiday.id.isNotEmpty)
                    _buildStatusInfoCard(
                      'Holiday',
                      holiday.title,
                      Icons.celebration_rounded,
                      Colors.purple,
                      colorScheme,
                    ),
                  if (leave != null)
                    _buildStatusInfoCard(
                      'On Leave',
                      leave.type,
                      Icons.event_busy_rounded,
                      Colors.blue,
                      colorScheme,
                    ),

                  SizedBox(height: 32),

                  // Timeline section
                  if (leave == null && holiday.id.isEmpty) ...[
                    Text(
                      'PUNCHING ACTIVITY',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildPunchingStepper(punches, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchingStepper(List<dynamic> punches, ColorScheme colorScheme) {
    if (punches.isEmpty) return SizedBox.shrink();

    List<Map<String, dynamic>> timelineEvents = [];
    for (var punch in punches) {
      if (punch['punchIn'] != null) {
        timelineEvents.add({
          'time': DateTime.parse(punch['punchIn']),
          'type': 'in',
          'label': 'Punch In',
          'color': Colors.green,
        });
      }
      if (punch['punchOut'] != null) {
        timelineEvents.add({
          'time': DateTime.parse(punch['punchOut']),
          'type': 'out',
          'label': 'Punch Out',
          'color': Colors.orange,
        });
      }
    }

    timelineEvents.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );

    return Column(
      children: timelineEvents.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isFirst = index == 0;
        final isLast = index == timelineEvents.length - 1;

        return TimelineTile(
          alignment: TimelineAlign.start,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: event['color'],
            padding: EdgeInsets.all(6),
            indicator: Container(
              decoration: BoxDecoration(
                color: event['color'],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: event['color'].withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          beforeLineStyle: LineStyle(
            color: colorScheme.outline.withOpacity(0.1),
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: colorScheme.outline.withOpacity(0.1),
            thickness: 2,
          ),
          endChild: Padding(
            padding: EdgeInsets.only(
              left: 16,
              top: 12,
              bottom: isLast ? 12 : 24,
            ),
            child: Row(
              children: [
                Text(
                  DateFormat(
                    'h:mm a',
                  ).format((event['time'] as DateTime).toLocal()),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: event['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (event['label'] as String).toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: event['color'],
                      letterSpacing: 0.5,
                    ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _backgroundColor;

  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
