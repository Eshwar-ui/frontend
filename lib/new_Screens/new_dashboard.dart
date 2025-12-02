import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/services/attendance_service.dart';
import 'package:quantum_dashboard/services/leave_service.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';

class new_dashboard extends StatefulWidget {
  const new_dashboard({super.key});

  @override
  State<new_dashboard> createState() => _new_dashboardState();
}

class _new_dashboardState extends State<new_dashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final LeaveService _leaveService = LeaveService();

  // Attendance data
  bool _isLoading = true;
  Attendance? _todayAttendance;
  List<Attendance> _todayPunches = [];
  int _presentDays = 0;
  int _absentDays = 0;
  int _leaveDays = 0;
  double _totalWorkTime = 0.0;
  double _totalBreakTime = 0.0;
  Timer? _workTimeTimer;
  late DateTime _selectedAnalyticsDate;

  @override
  void initState() {
    super.initState();
    _selectedAnalyticsDate = DateTime.now();
    // Wait for the widget to be fully built before accessing context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsDataForMonth(_selectedAnalyticsDate);
      _loadAttendanceData();
      _calculateTotalWorkTime(_todayPunches);
      _calculateTotalBreakTime(_todayPunches);
    });
  }

  @override
  void dispose() {
    _workTimeTimer?.cancel();
    super.dispose();
  }

  // Calculate total work time from all punch sessions for today
  double _calculateTotalWorkTime(List<Attendance> todayPunches) {
    double totalWorkTime = 0.0;
    final now = DateTime.now();

    for (var punch in todayPunches) {
      if (punch.punchOut != null) {
        // Completed session: punch out time - punch in time
        final workDuration = punch.punchOut!.difference(punch.punchIn);
        totalWorkTime += workDuration.inSeconds.toDouble();
        debugPrint(
          '📊 Work session: ${punch.punchIn.toLocal()} to ${punch.punchOut!.toLocal()} = ${workDuration.inSeconds} seconds',
        );
      } else {
        // Ongoing session: current time - punch in time
        final workDuration = now.difference(punch.punchIn);
        totalWorkTime += workDuration.inSeconds.toDouble();
        debugPrint(
          '📊 Ongoing work session: ${punch.punchIn.toLocal()} to now = ${workDuration.inSeconds} seconds',
        );
      }
    }

    debugPrint(
      '📊 Total work time: $totalWorkTime seconds (${(totalWorkTime / 3600).toStringAsFixed(2)} hours)',
    );
    return totalWorkTime;
  }

  // Start timer to update work time periodically when punched in
  void _startWorkTimeTimer(List<Attendance> todayPunches) {
    // Cancel existing timer
    _workTimeTimer?.cancel();

    // Check if user is currently punched in (has any punch without punch out)
    final hasOngoingSession = todayPunches.any(
      (punch) => punch.punchOut == null,
    );

    if (hasOngoingSession) {
      // Update every 30 seconds when punched in
      _workTimeTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        // Recalculate work time for ongoing session
        final updatedWorkTime = _calculateTotalWorkTime(todayPunches);

        if (mounted) {
          setState(() {
            _totalWorkTime = updatedWorkTime;
          });
        }
      });
    }
  }

  // Calculate total break time between consecutive punch sessions
  double _calculateTotalBreakTime(List<Attendance> todayPunches) {
    if (todayPunches.length < 2) {
      debugPrint('📊 Less than 2 punches, no break time calculation');
      return 0.0;
    }

    // Sort punches by punch in time to ensure correct order
    final sortedPunches = List<Attendance>.from(todayPunches);
    sortedPunches.sort((a, b) => a.punchIn.compareTo(b.punchIn));

    double totalBreakTime = 0.0;

    debugPrint(
      '📊 Calculating break time between ${sortedPunches.length} punches',
    );

    for (int i = 0; i < sortedPunches.length - 1; i++) {
      final currentPunch = sortedPunches[i];
      final nextPunch = sortedPunches[i + 1];

      // Break time = gap between current punch out and next punch in
      if (currentPunch.punchOut != null) {
        final breakStart = currentPunch.punchOut!;
        final breakEnd = nextPunch.punchIn;

        final breakDuration = breakEnd.difference(breakStart);
        final breakSeconds = breakDuration.inSeconds.toDouble();

        if (breakSeconds > 0) {
          totalBreakTime += breakSeconds;
          debugPrint(
            '📊 Break ${i + 1}: ${breakStart.toLocal()} to ${breakEnd.toLocal()} = ${breakSeconds} seconds (${(breakSeconds / 60).toStringAsFixed(1)} minutes)',
          );
        }
      }
    }

    debugPrint(
      '📊 Total break time: $totalBreakTime seconds (${(totalBreakTime / 3600).toStringAsFixed(2)} hours)',
    );
    return totalBreakTime;
  }

  Future<void> _loadAttendanceData() async {
    // Get auth provider reference before any async operations
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is logged in
    if (!authProvider.isLoggedIn) {
      debugPrint('❌ User is not logged in');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    // Store user data before async operations
    final user = authProvider.user;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      debugPrint('📊 Loading attendance data for ${user.fullName}...');

      // Fetch today's punches directly to get the most up-to-date data
      final todayPunchesResult = await _attendanceService.getPunches(
        user.employeeId,
        month: currentMonth,
        year: currentYear,
      );

      // Check if still mounted after async operations
      if (!mounted) return;

      // Filter all today's punches
      final allPunches = todayPunchesResult['punches'] as List<Attendance>;
      final todayPunches = allPunches.where((attendance) {
        final recordDate = DateTime(
          attendance.punchIn.year,
          attendance.punchIn.month,
          attendance.punchIn.day,
        );
        return recordDate.isAtSameMomentAs(today);
      }).toList();

      // Calculate work time and break time from today's punches
      final calculatedWorkTime = _calculateTotalWorkTime(todayPunches);
      final calculatedBreakTime = _calculateTotalBreakTime(todayPunches);

      // Find today's most recent attendance record
      Attendance? todayRecord;
      if (todayPunches.isNotEmpty) {
        // Sort by punch in time and get the most recent one
        todayPunches.sort((a, b) => b.punchIn.compareTo(a.punchIn));
        todayRecord = todayPunches.first;
      }

      if (mounted) {
        setState(() {
          _todayAttendance = todayRecord;
          _todayPunches = todayPunches;
          _isLoading = false;
          _totalWorkTime = calculatedWorkTime;
          _totalBreakTime = calculatedBreakTime;
        });

        // Start timer to update work time if user is punched in
        _startWorkTimeTimer(todayPunches);
      }

      debugPrint(
        '✅ Loaded today\'s attendance: TodayRecord=${todayRecord != null ? "Found" : "Not Found"}',
      );
      debugPrint(
        '✅ Today attendance isPunchedIn: ${todayRecord?.isPunchedIn ?? false}',
      );
    } catch (e) {
      debugPrint('❌ Error loading attendance: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAnalyticsDataForMonth(DateTime dateForMonth) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn || authProvider.user == null) return;

    final user = authProvider.user!;
    final month = dateForMonth.month;
    final year = dateForMonth.year;

    debugPrint(
      '📊 Loading analytics for ${DateFormat('MMMM yyyy').format(dateForMonth)}...',
    );

    try {
      // Fetch all punches for the given month to calculate analytics.
      // This is more reliable than dateWiseData which might have a different structure.
      final punchesResult = await _attendanceService.getPunches(
        user.employeeId,
        month: month,
        year: year,
      );

      if (!mounted) return;

      final allPunchesForMonth = punchesResult['punches'] as List<Attendance>;

      // Use a Set to count unique present days.
      // Only count weekdays that have a punch.
      final presentDaysSet = <DateTime>{};
      for (var punch in allPunchesForMonth) {
        final punchDay = DateTime(
          punch.punchIn.year,
          punch.punchIn.month,
          punch.punchIn.day,
        );
        if (punchDay.month == month &&
            punchDay.year == year &&
            punchDay.weekday != DateTime.saturday &&
            punchDay.weekday != DateTime.sunday) {
          presentDaysSet.add(punchDay);
        }
      }

      // Fetch and calculate leave days for the selected month

      int leaveDays = 0;

      final leaveDaysSet = <DateTime>{}; // Use a set to store unique leave days

      try {
        final leaves = await _leaveService.getMyLeaves(user.employeeId);

        final firstDayOfMonth = DateTime(year, month, 1);

        final lastDayOfMonth = DateTime(year, month + 1, 0);

        for (var leave in leaves) {
          // To count all applied leaves, we don't filter by status.
          // if (leave.status.toLowerCase() != 'approved') continue;

          final leaveStartInMonth = leave.from.isBefore(firstDayOfMonth)
              ? firstDayOfMonth
              : leave.from;
          final leaveEndInMonth = leave.to.isAfter(lastDayOfMonth)
              ? lastDayOfMonth
              : leave.to;

          if (leaveStartInMonth.isBefore(leaveEndInMonth) ||
              leaveStartInMonth.isAtSameMomentAs(leaveEndInMonth)) {
            for (
              var day = leaveStartInMonth;
              day.isBefore(leaveEndInMonth.add(const Duration(days: 1)));
              day = day.add(const Duration(days: 1))
            ) {
              if (day.month == month &&
                  day.year == year &&
                  day.weekday != DateTime.saturday &&
                  day.weekday != DateTime.sunday) {
                leaveDaysSet.add(
                  DateTime(day.year, day.month, day.day),
                ); // Add date only
              }
            }
          }
        }
        leaveDays = leaveDaysSet.length;
      } catch (e) {
        debugPrint('Error fetching leave data for analytics: $e');
        leaveDays = 0; // Ensure leaveDays is reset on error
      }

      // Calculate present, absent, and leave days
      int presentCount = presentDaysSet.length;
      int absentCount = 0;
      final today = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ); // Today's date without time
      final daysInMonth = DateTime(
        year,
        month + 1,
        0,
      ).day; // Number of days in the selected month

      for (int i = 1; i <= daysInMonth; i++) {
        final currentDay = DateTime(year, month, i);

        // Skip future days if the selected month is the current month
        if (currentDay.isAfter(today) &&
            currentDay.month == today.month &&
            currentDay.year == today.year) {
          continue; // Don't count future days in the current month as absent
        }

        // Only consider weekdays
        if (currentDay.weekday != DateTime.saturday &&
            currentDay.weekday != DateTime.sunday) {
          // If the day is not present and not a leave, it's an absent day
          if (!presentDaysSet.contains(currentDay) &&
              !leaveDaysSet.contains(
                DateTime(currentDay.year, currentDay.month, currentDay.day),
              )) {
            absentCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _presentDays = presentCount;
          _absentDays = absentCount;
          _leaveDays =
              leaveDays; // This is already calculated from leaveDaysSet.length
        });
      }
      debugPrint(
        '✅ Analytics for ${DateFormat('MMMM yyyy').format(dateForMonth)}: Present=$presentCount, Absent=$absentCount, Leaves=$leaveDays',
      );
    } catch (e) {
      debugPrint('❌ Error loading analytics data: $e');
      if (mounted) {
        setState(() {
          _presentDays = 0;
          _absentDays = 0;
          _leaveDays = 0;
        });
      }
    }
  }

  Future<void> _handlePunchInOut() async {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    // Store user data before async operations
    final user = authProvider.user;
    if (user == null) return;

    final isPunchedIn = _todayAttendance?.isPunchedIn ?? false;

    // Optimistically update the UI immediately for better UX
    // This creates a temporary attendance record to show the new state
    if (mounted) {
      setState(() {
        if (isPunchedIn) {
          // Punching out - set punchOut time (but keep the attendance object)
          if (_todayAttendance != null) {
            // We'll reload the actual data, but this prevents the button from flickering
            _isLoading = true;
          }
        } else {
          // Punching in - create a temporary attendance record with current time
          // This will be replaced with actual data from the server
          final now = DateTime.now();
          _todayAttendance = Attendance(
            id: 'temp',
            employeeId: user.employeeId,
            punchIn: now,
            punchOut: null, // null means punched in
            breakTime: _todayAttendance?.breakTime ?? 0.0,
            totalWorkingTime: _todayAttendance?.totalWorkingTime ?? 0.0,
            employeeName: user.fullName,
          );
          _isLoading = true;
        }
      });
    }

    try {
      if (isPunchedIn) {
        // Punch Out
        debugPrint('⏰ Punching out...');
        await _attendanceService.punchOut(user.employeeId, user.fullName);
        debugPrint('✅ Punched out successfully!');
      } else {
        // Punch In
        debugPrint('⏰ Punching in...');
        await _attendanceService.punchIn(user.employeeId, user.fullName);
        debugPrint('✅ Punched in successfully!');
      }

      // Check if still mounted after async operation
      if (!mounted) return;

      // Reload attendance data to get the actual server response
      await _loadAttendanceData();

      // Reload analytics data for the currently selected month
      await _loadAnalyticsDataForMonth(_selectedAnalyticsDate);

      // Show success message - check mounted and get ScaffoldMessenger only when needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPunchedIn
                  ? 'Punched out successfully!'
                  : 'Punched in successfully!',
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error during punch: $e');

      // On error, reload the actual data to revert optimistic update
      if (mounted) {
        await _loadAttendanceData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/illustrations/loading.json'),
                  SizedBox(height: 16),
                  Text(
                    'Loading attendance data...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildDateandTime(),
                  _buildPunchButton(),
                  _buildPunchHistory(),

                  // Timeline Section
                  SizedBox(height: 24),
                  _buildTimeline(),

                  // User Analytics Section: Attendance, Leaves, and Their Status
                  // SizedBox(height: 24),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 24),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           Text(
                  //             'Your Analytics',
                  //             style: GoogleFonts.poppins(
                  //               fontSize: 20,
                  //               fontWeight: FontWeight.w600,
                  //               color: colorScheme.onSurface,
                  //             ),
                  //           ),
                  //           _buildMonthSelector(),
                  //         ],
                  //       ),
                  //       SizedBox(height: 12),
                  //       Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //         children: [
                  //           // Attendance Card
                  //           _AnalyticsCard(
                  //             title: 'Attendance',
                  //             count: _presentDays,
                  //             status: 'Present',
                  //             color: Colors.green,
                  //             icon: Icons.check_circle,
                  //           ),
                  //           // Absent Card
                  //           _AnalyticsCard(
                  //             title: 'Absent',
                  //             count: _absentDays,
                  //             status: 'Absent',
                  //             color: Colors.red,
                  //             icon: Icons.cancel,
                  //           ),
                  //           // Leave Card
                  //           _AnalyticsCard(
                  //             title: 'Leaves',
                  //             count: _leaveDays,
                  //             status: 'On Leave',
                  //             color: Colors.orange,
                  //             icon: Icons.event_busy,
                  //           ),
                  //         ],
                  //       ),
                  //       SizedBox(height: 16),
                  //       // Status Pills (present/absent/leave in past week)
                  //       // Row(
                  //       //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //       //   children: [
                  //       //     _StatusPill(
                  //       //       label: 'Present',
                  //       //       value: '5',
                  //       //       color: Colors.green,
                  //       //       icon: Icons.check,
                  //       //     ),
                  //       //     _StatusPill(
                  //       //       label: 'Absent',
                  //       //       value: '1',
                  //       //       color: Colors.red,
                  //       //       icon: Icons.close,
                  //       //     ),
                  //       //     _StatusPill(
                  //       //       label: 'Leave',
                  //       //       value: '1',
                  //       //       color: Colors.orange,
                  //       //       icon: Icons.hourglass_empty,
                  //       //     ),
                  //       //   ],
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: 120), // Extra padding for nav bar
                ],
              ),
            ),
    );
  }

  bool _isNextMonthAvailable() {
    final now = DateTime.now();
    final nextMonth = DateTime(
      _selectedAnalyticsDate.year,
      _selectedAnalyticsDate.month + 1,
      1,
    );
    return nextMonth.isBefore(DateTime(now.year, now.month + 1, 1));
  }

  Widget _buildMonthSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, color: colorScheme.primary),
          onPressed: () {
            setState(() {
              _selectedAnalyticsDate = DateTime(
                _selectedAnalyticsDate.year,
                _selectedAnalyticsDate.month - 1,
                1,
              );
            });
            _loadAnalyticsDataForMonth(_selectedAnalyticsDate);
          },
        ),
        Text(
          DateFormat('MMM yyyy').format(_selectedAnalyticsDate),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            color: _isNextMonthAvailable() ? colorScheme.primary : Colors.grey,
          ),
          onPressed: !_isNextMonthAvailable()
              ? null
              : () {
                  setState(() {
                    _selectedAnalyticsDate = DateTime(
                      _selectedAnalyticsDate.year,
                      _selectedAnalyticsDate.month + 1,
                      1,
                    );
                  });
                  _loadAnalyticsDataForMonth(_selectedAnalyticsDate);
                },
        ),
      ],
    );
  }

  Widget _buildDateandTime() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final date = now.day;
    final month = now.month;
    final year = now.year;
    final hour12 = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final amPm = now.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '$hour12:${now.minute.toString().padLeft(2, '0')} $amPm';

    String _monthToString(int month) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return months[month - 1];
    }

    String _weekdayToString(int weekday) {
      const weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      // Dart's DateTime.weekday returns 1 for Monday ... 7 for Sunday
      return weekdays[weekday - 1];
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            formattedTime,
            style: GoogleFonts.poppins(
              fontSize: 60,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            '${_monthToString(month)} $date $year - ${_weekdayToString(DateTime.now().weekday)}',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isPunchedIn = _todayAttendance?.isPunchedIn ?? false;

    // Neumorphic design - optimized for dark mode
    if (isDark) {
      return GestureDetector(
        onTap: _handlePunchInOut,
        child: Container(
          padding: EdgeInsets.all(40),
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPunchedIn
                    ? [Color(0xFF2196F3), Color(0xFF1565C0)]
                    : [
                        colorScheme.surfaceContainerHighest,
                        colorScheme.surface,
                      ],
              ),
              boxShadow: [
                // Neumorphic dark shadow - bottom right
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: Offset(15, 15),
                  blurRadius: 30,
                  spreadRadius: -30,
                ),
                // Neumorphic light shadow - top left
                // BoxShadow(
                //   color: Colors.white.withValues(alpha: 0.2),
                //   offset: Offset(-15, -15),
                //   blurRadius: 30,
                //   spreadRadius: 0,
                // ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surfaceContainerHighest.withOpacity(0.9),
                    colorScheme.surface.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  // Inner dark shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: Offset(10, 10),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                  // Inner light highlight
                  BoxShadow(
                    color: Colors.white.withOpacity(0.15),
                    offset: Offset(-10, -10),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainer,
                  boxShadow: [
                    // Deep inner dark shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.7),
                      offset: Offset(8, 8),
                      blurRadius: 24,
                      spreadRadius: -10,
                    ),
                    // Deep inner light highlight
                    BoxShadow(
                      color: Colors.white.withOpacity(0.12),
                      offset: Offset(-8, -8),
                      blurRadius: 24,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: isPunchedIn
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        isPunchedIn ? 'Punch Out' : 'Punch In',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Light mode - original design
    return GestureDetector(
      onTap: _handlePunchInOut,
      child: Container(
        padding: EdgeInsets.all(40),
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPunchedIn
                  ? [Color(0xFF2196F3), Color(0xFF1565C0)]
                  : [Color(0xFFE6E9ED), Color(0xFFD1D5DB)],
            ),
            boxShadow: [
              // Outer shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              // Outer highlight - top left
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                offset: Offset(-12, -12),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF5F7FA), Color(0xFFE8EAED)],
              ),
              boxShadow: [
                // Inner shadow effect - creates the inset ring
                BoxShadow(
                  color: const Color(0xFFB8BEC5).withOpacity(0.6),
                  offset: Offset(8, 8),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  offset: Offset(-8, -8),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEFF1F4),
                boxShadow: [
                  // Deep inner shadow for the center
                  BoxShadow(
                    color: const Color(0xFFD1D5DB).withOpacity(0.5),
                    offset: Offset(6, 6),
                    blurRadius: 20,
                    spreadRadius: -8,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: Offset(-6, -6),
                    blurRadius: 20,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: isPunchedIn
                          ? Colors.redAccent
                          : Colors.greenAccent,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      isPunchedIn ? 'Punch Out' : 'Punch In',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String? firstName) {
    final initial = firstName?.substring(0, 1).toUpperCase() ?? 'Q';

    if (imageUrl == null || imageUrl.isEmpty) {
      // Show initial if no image URL
      return Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // Validate URL format
    final uri = Uri.tryParse(imageUrl);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      // Show initial if invalid URL
      return Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    try {
      return ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Show initial if image fails to load
            return Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    } catch (e) {
      // Fallback to initial if any error occurs
      return Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  Widget _buildAvatar(
    String? profileImage,
    String? firstName,
    ColorScheme colorScheme,
  ) {
    if (profileImage != null && profileImage.isNotEmpty) {
      // Handle base64 images (data:image...)
      if (profileImage.startsWith('data:image')) {
        try {
          final String base64String = profileImage.split(',').last;
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary,
            backgroundImage: MemoryImage(bytes),
            child: _buildProfileImage(null, firstName),
          );
        } catch (_) {
          // Fallback to initials if base64 decode fails
          return CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary,
            child: _buildProfileImage(null, firstName),
          );
        }
      } else {
        // Handle network images
        try {
          final uri = Uri.tryParse(profileImage);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            return CircleAvatar(
              radius: 32,
              backgroundColor: colorScheme.primary,
              foregroundImage: NetworkImage(profileImage),
              onForegroundImageError: (exception, stackTrace) {
                // If network image fails, fallback to initials
              },
              child: _buildProfileImage(null, firstName),
            );
          }
        } catch (_) {
          // Fallback to initials if URI parsing fails
        }
      }
    }

    // Fallback to initials if no image or invalid image
    return CircleAvatar(
      radius: 32,
      backgroundColor: colorScheme.primary,
      child: _buildProfileImage(null, firstName),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final firstName = user?.firstName;

    final userpicture = user?.profileImage;

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        return 'Good Morning';
      } else if (hour >= 12 && hour < 17) {
        return 'Good Afternoon';
      } else {
        return 'Good Evening';
      }
    }

    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          // Here, you would get the user name and profile info, but for this rewrite,
          // we'll show a sample name and pretend profile image (using initials).
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey $firstName',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${getGreeting()}, Mark your attendance',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              debugPrint(
                "Current page before tap: ${Provider.of<NavigationProvider>(context, listen: false).currentPage}",
              );
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setCurrentPage(NavigationPage.Profile);
            },
            child: _buildAvatar(userpicture, firstName, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildPunchHistory() {
    // Get first punch in time for today (the earliest punchIn among today's attendance records)
    DateTime? firstPunchInTime;
    if (_todayPunches.isNotEmpty) {
      final sortedTodayPunches = List<Attendance>.from(_todayPunches);
      sortedTodayPunches.sort(
        (a, b) => a.punchIn.compareTo(b.punchIn),
      ); // Sort ascending for earliest
      firstPunchInTime = sortedTodayPunches.first.punchIn;
    }

    // Convert work time from seconds to duration
    final workSeconds = _totalWorkTime.toInt();
    final totalWorkDuration = Duration(seconds: workSeconds);

    // Convert break time from seconds to duration
    final breakSeconds = _totalBreakTime.toInt();
    final totalBreakDuration = Duration(seconds: breakSeconds);

    // Formatting functions
    String formatTime(DateTime? time) {
      if (time == null) return '--:--';
      final hour = time.hour > 12
          ? time.hour - 12
          : time.hour == 0
          ? 12
          : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    String formatDuration(Duration? duration) {
      if (duration == null || duration.inMinutes == 0) return '00:00';
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // For dark mode, use cards/containers with dark/neutral backgrounds and subtle borders or drop-shadows
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme
                  .surfaceContainerHighest // very dark, elegant background
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.08),
          width: 1.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(-8, -8),
                ),
              ]
            : [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Punch In
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.login, color: colorScheme.primary, size: 32),
              ),
              SizedBox(height: 8),
              Text(
                formatTime(firstPunchInTime),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                'Punch In',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          // Work time
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              SizedBox(height: 8),
              Text(
                formatDuration(totalWorkDuration),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                'Work time',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          // Break time
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.primary.withOpacity(0.15)
                      : colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.free_breakfast,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              SizedBox(height: 8),
              Text(
                formatDuration(totalBreakDuration),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                'Break time',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_todayPunches.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.08,
            ),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'No activities yet.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Sort punches by punch in time to ensure chronological order
    final sortedPunches = List<Attendance>.from(_todayPunches);
    sortedPunches.sort((a, b) => a.punchIn.compareTo(b.punchIn));

    // Create a flat list of timeline events
    List<Map<String, dynamic>> timelineEvents = [];
    for (var punch in sortedPunches) {
      // Add punch in event
      timelineEvents.add({
        'type': 'punchIn',
        'time': punch.punchIn,
        'label': 'Punch In',
      });

      // Add punch out event if exists
      if (punch.punchOut != null) {
        timelineEvents.add({
          'type': 'punchOut',
          'time': punch.punchOut!,
          'label': 'Punch Out',
        });
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(isDark ? 0.2 : 0.08),
          width: 1.5,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.04),
                  blurRadius: 8,
                  offset: Offset(-8, -8),
                ),
              ]
            : [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.04),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Activities',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Column(
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
                  padding: EdgeInsets.only(
                    left: 16,
                    top: 8,
                    bottom: isLast ? 0 : 12,
                  ),
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
                        DateFormat.jm().format(event['time'].toLocal()),
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
          ),
        ],
      ),
    );
  }
}

// Analytics Card Component
class _AnalyticsCard extends StatelessWidget {
  final String title;
  final int count;
  final String status;
  final Color color;
  final IconData icon;

  const _AnalyticsCard({
    required this.title,
    required this.count,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 105,
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.5 : 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : color.withOpacity(0.1),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? colorScheme.onSurface : Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? colorScheme.onSurface.withOpacity(0.7)
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
