import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/services/attendance_service.dart';
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
  final AttendanceService _attendanceService = AttendanceService();
  Attendance? _todayAttendance;
  bool _isLoading = false;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _getTodayAttendance();
  }

  Future<void> _getTodayAttendance() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final attendance = await _attendanceService.getTodayAttendance();
      setState(() {
        _todayAttendance = attendance;
        if (_todayAttendance != null && _todayAttendance!.checkIns.isNotEmpty) {
          final lastCheckIn = _todayAttendance!.checkIns.last;
          _isCheckedIn = lastCheckIn.checkOutTime == null;
        } else {
          _isCheckedIn = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCheckInOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Attendance? attendance;
      if (_isCheckedIn) {
        attendance = await _attendanceService.checkOut();
      } else {
        attendance = await _attendanceService.checkIn();
      }
      setState(() {
        _todayAttendance = attendance;
        if (_todayAttendance != null && _todayAttendance!.checkIns.isNotEmpty) {
          final lastCheckIn = _todayAttendance!.checkIns.last;
          _isCheckedIn = lastCheckIn.checkOutTime == null;
        } else {
          _isCheckedIn = false;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE, MMM d, yyyy');
    return formatter.format(now);
  }

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String checker = _isCheckedIn ? 'Checked In' : 'Checked Out';

    return SingleChildScrollView(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return Center(child: CircularProgressIndicator());
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
                      LoadingDotsAnimation(),
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
                                '${user.firstName} ${user.lastName}',
                                style: AppTextStyles.subheading,
                              ),
                              Text(
                                'Employee ID: ${user.employeeId ?? 'N/A'}',
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
                            value: user.employeeId ?? 'N/A',
                          ),
                          Container(width: 1, height: 50, color: Colors.grey),
                          _employeeDetails(
                            title: 'Joining Date',
                            value: user.joinDate != null
                                ? DateFormat.yMMMd().format(user.joinDate!)
                                : 'N/A',
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
                      SizedBox(height: 24),

                      // Check In Button
                      if (_isLoading)
                        CircularProgressIndicator()
                      else
                        CustomButton(
                          text: _isCheckedIn ? 'Check Out' : 'Check In',
                          onPressed: _toggleCheckInOut,
                        ),
                      SizedBox(height: 16),

                      // Working Time Display
                      Row(
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
                                  text: _formatDuration(
                                    _todayAttendance?.totalWorkingTime ?? 0,
                                  ),
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
                                  text: _formatDuration(
                                    _todayAttendance?.totalBreakTime ?? 0,
                                  ),
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
                      SizedBox(height: 24),

                      // Today Activities
                      Text('Today Activities', style: AppTextStyles.subheading),
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
    );
  }

  Widget _buildTimeline() {
    if (_todayAttendance == null || _todayAttendance!.checkIns.isEmpty) {
      return Center(child: Text('No activities yet.'));
    }
    return Column(
      children: _todayAttendance!.checkIns.map((checkIn) {
        return Column(
          children: [
            TimelineTile(
              alignment: TimelineAlign.start,
              indicatorStyle: IndicatorStyle(width: 20, color: Colors.blue),
              beforeLineStyle: const LineStyle(
                color: Colors.grey,
                thickness: 2,
              ),
              endChild: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Check In at ${DateFormat.jm().format(checkIn.checkInTime.toLocal())}',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            if (checkIn.checkOutTime != null)
              TimelineTile(
                alignment: TimelineAlign.start,
                indicatorStyle: IndicatorStyle(width: 20, color: Colors.blue),
                beforeLineStyle: LineStyle(color: Colors.grey, thickness: 2),
                endChild: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Check Out at ${DateFormat.jm().format(checkIn.checkOutTime!.toLocal())}',
                    style: TextStyle(fontSize: 14),
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
