import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:quantum_dashboard/models/holiday_model.dart';
import 'package:quantum_dashboard/services/attendance_service.dart';
import 'package:quantum_dashboard/services/holiday_service.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final HolidayService _holidayService = HolidayService();
  late Future<List<Attendance>> _attendanceFuture;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  
  // Calendar related variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Attendance>> _events = {};
  Map<DateTime, Holiday> _holidays = {};

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() {
    setState(() {
      _attendanceFuture = _attendanceService.getMyAttendance(
        year: _selectedYear,
        month: _selectedMonth,
      );
    });
    
    // Load attendance data for calendar
    _loadAttendanceForCalendar();
  }

  Future<void> _loadAttendanceForCalendar() async {
    try {
      final attendanceList = await _attendanceService.getMyAttendance(
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      // Load holidays for the selected year
      final holidays = await _holidayService.getHolidaysByYear(_selectedYear);
      
      // Group attendance by date
      final Map<DateTime, List<Attendance>> events = {};
      for (var attendance in attendanceList) {
        final date = DateTime(attendance.date.year, attendance.date.month, attendance.date.day);
        if (events[date] == null) events[date] = [];
        events[date]!.add(attendance);
      }
      
      // Group holidays by date
      final Map<DateTime, Holiday> holidayMap = {};
      for (var holiday in holidays) {
        final parsedDate = holiday.parsedDate;
        if (parsedDate != null) {
          final date = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
          holidayMap[date] = holiday;
        }
      }
      
      setState(() {
        _events = events;
        _holidays = holidayMap;
      });
    } catch (e) {
      print('Error loading attendance for calendar: $e');
    }
  }

  List<Attendance> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  Holiday? _getHolidayForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _holidays[date];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
          // _buildFilter(),
          Expanded(
            child: _buildCalendarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<int>(
            isExpanded: true,
            autofocus: true,
            underline: Container(),
            alignment: Alignment.centerLeft,
            dropdownColor: Colors.white,
            focusColor: Colors.white,
            value: _selectedYear,
            items: List.generate(5, (index) {
              final year = DateTime.now().year - index;
              return DropdownMenuItem(
                value: year,
                child: Center(child: Text(year.toString())),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedYear = value;
                  _loadAttendance();
                });
              }
            },
          ),
          SizedBox(width: 20),
          DropdownButton<int>(
            isExpanded: true,
            value: _selectedMonth,
            items: List.generate(12, (index) {
              final month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Center(
                  child: Text(DateFormat.MMMM().format(DateTime(0, month))),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMonth = value;
                  _loadAttendance();
                });
              }
            },
          ),
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
        children: [
          TableCalendar(
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
              _showAttendanceDetails(selectedDay);
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
              defaultDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
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
                        color: _getMarkerColor(attendance.status),
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
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, {bool isSelected = false, bool isToday = false}) {
    final events = _getEventsForDay(date);
    final holiday = _getHolidayForDay(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    
    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;
    
    // Check for holiday first (highest priority)
    if (holiday != null) {
      backgroundColor = Colors.purple.withOpacity(0.2);
      textColor = Colors.purple[800]!;
    }
    // Then check attendance status
    else if (events.isNotEmpty) {
      final attendance = events.first as Attendance;
      
      // Check if there are incomplete check-ins (no check-out)
      bool hasIncompleteCheckIn = attendance.checkIns.any((checkIn) => checkIn.checkOutTime == null);
      
      String effectiveStatus = attendance.status.toLowerCase();
      
      // If there are incomplete check-ins, treat as absent
      if (hasIncompleteCheckIn && effectiveStatus != 'absent') {
        effectiveStatus = 'absent';
      }
      
      switch (effectiveStatus) {
        case 'present':
          backgroundColor = Colors.green.withOpacity(0.2);
          textColor = Colors.green[800]!;
          break;
        case 'halfday':
          backgroundColor = Colors.orange.withOpacity(0.2);
          textColor = Colors.orange[800]!;
          break;
        case 'absent':
          backgroundColor = Colors.red.withOpacity(0.2);
          textColor = Colors.red[800]!;
          break;
        default:
          backgroundColor = Colors.grey.withOpacity(0.1);
          textColor = Colors.grey[700]!;
      }
    }
    // Then check if it's weekend
    else if (isWeekend) {
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey[600]!;
    }
    
    // Override colors for selected and today states
    if (isSelected) {
      backgroundColor = Color(0xFF1976D2);
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.orange;
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
                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
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
    return Container(
      padding: EdgeInsets.all(16),
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
            children: [
              _buildLegendItem('Present', Colors.green, Icons.check_circle),
              _buildLegendItem('Half Day', Colors.orange, Icons.schedule),
              _buildLegendItem('Absent', Colors.red, Icons.cancel),
              _buildLegendItem('Holiday', Colors.purple, Icons.celebration),
              _buildLegendItem('Weekend', Colors.grey, Icons.weekend),
              _buildLegendItem('Today', Colors.orange, Icons.today),
              _buildLegendItem('Selected', Color(0xFF1976D2), Icons.radio_button_checked),
            ],
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'halfday':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'present':
        chipColor = Colors.green;
        break;
      case 'halfday':
        chipColor = Colors.orange;
        break;
      case 'absent':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

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

  String _formatDuration(double milliseconds) {
    final duration = Duration(milliseconds: milliseconds.toInt());
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _showAttendanceDetails(DateTime selectedDate) {
    final events = _getEventsForDay(selectedDate);
    final holiday = _getHolidayForDay(selectedDate);
    final isWeekend = selectedDate.weekday == DateTime.saturday || selectedDate.weekday == DateTime.sunday;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAttendanceModal(selectedDate, events, holiday, isWeekend),
    );
  }

  Widget _buildAttendanceModal(DateTime date, List<Attendance> events, Holiday? holiday, bool isWeekend) {
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
                      Icon(Icons.calendar_today, color: Color(0xFF1976D2), size: 24),
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

  Widget _buildStatusIndicator(List<Attendance> events, Holiday? holiday, bool isWeekend) {
    String status;
    Color statusColor;
    IconData statusIcon;
    String? additionalInfo;

    if (holiday != null) {
      status = 'Holiday - ${holiday.holidayName}';
      statusColor = Colors.purple;
      statusIcon = Icons.celebration;
    } else if (events.isNotEmpty) {
      final attendance = events.first;
      
      // Check if there are incomplete check-ins
      bool hasIncompleteCheckIn = attendance.checkIns.any((checkIn) => checkIn.checkOutTime == null);
      
      String effectiveStatus = attendance.status.toLowerCase();
      
      if (hasIncompleteCheckIn && effectiveStatus != 'absent') {
        status = 'ABSENT';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        additionalInfo = 'Marked absent due to incomplete check-out';
      } else {
        status = attendance.status.toUpperCase();
        switch (effectiveStatus) {
          case 'present':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'halfday':
            statusColor = Colors.orange;
            statusIcon = Icons.schedule;
            break;
          case 'absent':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help_outline;
        }
      }
    } else if (isWeekend) {
      status = 'Weekend';
      statusColor = Colors.grey;
      statusIcon = Icons.weekend;
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

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Working Hours',
                _formatDuration(attendance.totalWorkingTime),
                Icons.timer,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Break Hours',
                _formatDuration(attendance.totalBreakTime),
                Icons.free_breakfast,
                Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),

        // Check-in/Check-out details
        Text(
          'Time Details',
          style: AppTextStyles.subheading.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),

        ...attendance.checkIns.asMap().entries.map((entry) {
          final index = entry.key;
          final checkIn = entry.value;
          final duration = checkIn.checkOutTime != null
              ? checkIn.checkOutTime!.difference(checkIn.checkInTime)
              : Duration.zero;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                if (attendance.checkIns.length > 1)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Session ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeDetail(
                        'Check In',
                        DateFormat.jm().format(checkIn.checkInTime.toLocal()),
                        Icons.login,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeDetail(
                        'Check Out',
                        checkIn.checkOutTime != null
                            ? DateFormat.jm().format(checkIn.checkOutTime!.toLocal())
                            : 'Still Active',
                        Icons.logout,
                        checkIn.checkOutTime != null ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildTimeDetail(
                  'Duration',
                  _formatDuration(duration.inMilliseconds.toDouble()),
                  Icons.schedule,
                  Colors.blue,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildTimeDetail(String label, String value, IconData icon, Color color) {
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
            holiday.holidayName,
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.purple[600],
            ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
