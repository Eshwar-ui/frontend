import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/utils/constants.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_button.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';
import 'package:quantum_dashboard/widgets/loading_dots_animation.dart';
import 'package:timeline_tile/timeline_tile.dart';

class DashboardContent extends StatefulWidget {
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  Attendance? _todayAttendance;
  List<Attendance> _todayPunches = [];
  bool _isLoading = false;
  bool _isCheckedIn = false;

  Future<void> _refreshDashboard() async {
    await _getTodayAttendance();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getTodayAttendance();
    });
  }

  Future<void> _getTodayAttendance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    if (user == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Get today's punches
      await attendanceProvider.getPunches(user.employeeId);

      // Find today's attendance record
      final today = DateTime.now();
      final todayPunches = attendanceProvider.punches.where((punch) {
        return punch.punchIn.year == today.year &&
            punch.punchIn.month == today.month &&
            punch.punchIn.day == today.day;
      }).toList();

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _todayPunches = todayPunches;
              if (todayPunches.isNotEmpty) {
                _todayAttendance = todayPunches.first;
                // Check if the last punch is a punch in (meaning user is checked in)
                final lastPunch = todayPunches.last;
                _isCheckedIn = lastPunch.punchOut == null;

                // Debug logging for break time
                print('Dashboard: Today\'s attendance data loaded');
                print(
                  'Dashboard: _todayAttendance.lastPunchedIn: ${_todayAttendance?.lastPunchedIn}',
                );
                print(
                  'Dashboard: _todayAttendance.lastPunchedOut: ${_todayAttendance?.lastPunchedOut}',
                );
                print(
                  'Dashboard: _todayAttendance.formattedBreakTime: ${_todayAttendance?.formattedBreakTime}',
                );
                print('Dashboard: Total punches today: ${todayPunches.length}');
                for (int i = 0; i < todayPunches.length; i++) {
                  final punch = todayPunches[i];
                  print(
                    'Dashboard: Punch $i - lastPunchedIn: ${punch.lastPunchedIn}, lastPunchedOut: ${punch.lastPunchedOut}',
                  );
                }
              } else {
                _todayAttendance = null;
                _isCheckedIn = false;
              }
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleCheckInOut() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    if (user == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Map<String, dynamic> result;
      if (_isCheckedIn) {
        result = await attendanceProvider.punchOut(
          user.employeeId,
          user.fullName,
          position.latitude,
          position.longitude,
        );
      } else {
        result = await attendanceProvider.punchIn(
          user.employeeId,
          user.fullName,
          position.latitude,
          position.longitude,
        );
      }

      if (result['success'] != false) {
        // Refresh today's attendance
        await _getTodayAttendance();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Action completed successfully',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Action failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, MMM d, yyyy');
    return formatter.format(now);
  }

  String? _getFirstCheckInTime() {
    if (_todayAttendance == null) {
      return null;
    }
    return DateFormat.jm().format(_todayAttendance!.punchIn.toLocal());
  }

  // Calculate total working time for today
  // ignore: unused_element
  double _getTotalWorkingTime() {
    double totalWorkingTime = 0.0;
    for (var punch in _todayPunches) {
      totalWorkingTime += punch.totalWorkingTime;
    }
    return totalWorkingTime;
  }

  // Calculate total break time for today
  // ignore: unused_element
  double _getTotalBreakTime() {
    if (_todayPunches.length < 2) {
      print(
        'Dashboard: Less than 2 punches, no break time calculation possible',
      );
      return 0.0;
    }

    double totalBreakTime = 0.0;

    // Sort punches by punch in time to ensure correct order
    final sortedPunches = List<Attendance>.from(_todayPunches);
    sortedPunches.sort((a, b) => a.punchIn.compareTo(b.punchIn));

    print(
      'Dashboard: Calculating break time between ${sortedPunches.length} punches',
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
          print(
            'Dashboard: Break ${i + 1}: ${breakStart.toLocal()} to ${breakEnd.toLocal()} = ${breakSeconds} seconds',
          );
        }
      }
    }

    print('Dashboard: Total break time calculated: $totalBreakTime seconds');
    return totalBreakTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String checker = _isCheckedIn ? 'Checked In' : 'Checked Out';

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.user;
            if (user == null) {
              return Center(
                child: LoadingDotsAnimation(color: Color(0xFF1976D2), size: 10),
              );
            }
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomFloatingContainer(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'You are in $checker time',
                          style: AppTextStyles.body,
                        ),
                        SizedBox(width: 10),
                        LoadingDotsAnimation(
                          color: _isCheckedIn
                              ? Colors.green.shade300
                              : Colors.red.shade300,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Employee Info Card
                  CustomFloatingContainer(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(AppAssets.avatarPng),
                                  fit: BoxFit.cover,
                                ),
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 12),
                            // name and position
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.firstName}${user.lastName}',
                                  style: AppTextStyles.subheading,
                                ),
                                Text(
                                  '${user.designation}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _employeeDetails(
                              title: 'Employee ID',
                              value: user.employeeId,
                            ),
                            Container(width: 1, height: 50, color: Colors.grey),
                            _employeeDetails(
                              title: 'Joining Date',
                              value: user.joiningDate
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                              // value: DateFormat.yMMMd().format(user.joiningDate),
                            ),
                            Container(width: 1, height: 50, color: Colors.grey),
                            _employeeDetails(
                              title: 'Department',
                              value: user.department ?? 'N/A',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Today Date
                  CustomFloatingContainer(
                    width: double.infinity,
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Today Date: ',
                                style: AppTextStyles.body.copyWith(
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              TextSpan(
                                text: _getFormattedDate(),
                                style: AppTextStyles.body,
                              ),
                            ],
                          ),
                        ),
                        // First check-in time text
                        if (_getFirstCheckInTime() != null) ...[
                          SizedBox(height: 8),
                          Text(
                            'You started your day at ${_getFirstCheckInTime()}',
                            style: AppTextStyles.body.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              // fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        SizedBox(height: 24),

                        // Check In Button
                        if (_isLoading)
                          LoadingDotsAnimation(
                            color: Color(0xFF1976D2),
                            size: 8,
                          )
                        else
                          CustomButton(
                            text: _isCheckedIn ? 'Check Out' : 'Check In',
                            onPressed: _toggleCheckInOut,
                          ),
                        SizedBox(height: 16),

                        // Working Time Display
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Working Time ',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          _todayAttendance
                                              ?.formattedWorkingTime ??
                                          '00:00:00',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Break Time ',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          _todayAttendance
                                              ?.formattedBreakTime ??
                                          '00:00:00',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Today Activities
                        Text(
                          'Today Activities',
                          style: AppTextStyles.subheading,
                        ),
                        SizedBox(height: 12),
                        _buildTimeline(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_todayPunches.isEmpty) {
      return Center(child: Text('No activities yet.'));
    }

    return Column(
      children: _todayPunches.asMap().entries.map((entry) {
        final index = entry.key;
        final punch = entry.value;
        final isLast = index == _todayPunches.length - 1;

        return Column(
          children: [
            // Punch In
            Padding(
              padding: const EdgeInsets.only(left: 2.0, bottom: 12),
              child: TimelineTile(
                alignment: TimelineAlign.start,
                indicatorStyle: IndicatorStyle(
                  width: 12,
                  color: Colors.lightBlue.shade400,
                ),
                beforeLineStyle: LineStyle(
                  color: Colors.grey,
                  thickness: isLast ? 0 : 2,
                ),
                endChild: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                  child: Text(
                    'Punch In at ${DateFormat.jm().format(punch.punchIn.toLocal())}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            // Punch Out (if exists)
            if (punch.punchOut != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TimelineTile(
                  alignment: TimelineAlign.start,
                  indicatorStyle: IndicatorStyle(width: 16, color: Colors.blue),
                  beforeLineStyle: LineStyle(
                    color: Colors.grey,
                    thickness: isLast ? 0 : 2,
                  ),
                  endChild: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    child: Text(
                      'Punch Out at ${DateFormat.jm().format(punch.punchOut!.toLocal())}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

class _employeeDetails extends StatelessWidget {
  final String title;
  final String value;
  const _employeeDetails({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
