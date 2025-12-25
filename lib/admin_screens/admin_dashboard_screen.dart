import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/widgets/notification_icon_widget.dart';
import 'package:quantum_dashboard/widgets/send_notification_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/services/department_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Department> _departments = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data for stats
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
      Provider.of<LeaveProvider>(context, listen: false).getAllLeaves();
      _loadDepartments();
    });
  }

  Future<void> _loadDepartments() async {
    try {
      final deptService = DepartmentService();
      _departments = await deptService.getDepartments();
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsGrid(),
            _buildManagementSection(),
            _buildChartsSection(),
            SizedBox(height: 120), // Extra padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final firstName = user?.firstName ?? 'Admin';

    // Safe substring for avatar
    final avatarText = firstName.isNotEmpty
        ? firstName.substring(0, 1).toUpperCase()
        : 'A';

    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $firstName',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Admin Dashboard Overview',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Spacer(),
          SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SendNotificationDialog(),
              );
            },
            tooltip: 'Send Notification',
          ),
          SizedBox(width: 8),
          NotificationIconWidget(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer2<EmployeeProvider, LeaveProvider>(
      builder: (context, employeeProvider, leaveProvider, child) {
        final employeeCount = employeeProvider.employees.length;
        final allLeaves = leaveProvider.leaves;
        final pendingLeaves = allLeaves
            .where((leave) => leave.status.toLowerCase().trim() == 'pending')
            .length;
        final approvedLeaves = allLeaves
            .where(
              (leave) =>
                  leave.status.toLowerCase().trim() == 'approved' ||
                  leave.status.toLowerCase().trim().contains('approv'),
            )
            .length;
        final rejectedLeaves = allLeaves
            .where(
              (leave) =>
                  leave.status.toLowerCase().trim() == 'rejected' ||
                  leave.status.toLowerCase().trim() == 'declined' ||
                  leave.status.toLowerCase().trim().contains('reject'),
            )
            .length;
        final totalLeaves = allLeaves.length;
        final departmentCount = _departments.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Employees',
                      employeeCount.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Departments',
                      departmentCount.toString(),
                      Icons.business,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildStatCard(
              //         'Pending Leaves',
              //         pendingLeaves.toString(),
              //         Icons.assignment_late,
              //         Colors.orange,
              //       ),
              //     ),
              //     SizedBox(width: 16),
              //     Expanded(
              //       child: _buildStatCard(
              //         'Approved Leaves',
              //         approvedLeaves.toString(),
              //         Icons.check_circle,
              //         Colors.green,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 16),
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildStatCard(
              //         'Rejected Leaves',
              //         rejectedLeaves.toString(),
              //         Icons.cancel,
              //         Colors.red,
              //       ),
              //     ),
              //     SizedBox(width: 16),
              //     Expanded(
              //       child: _buildStatCard(
              //         'Total Leaves',
              //         totalLeaves.toString(),
              //         Icons.event_note,
              //         Colors.teal,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Consumer2<EmployeeProvider, LeaveProvider>(
      builder: (context, employeeProvider, leaveProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics & Insights',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16),
              // Leave Status Pie Chart
              // _buildLeaveStatusChart(leaveProvider.leaves),
              // SizedBox(height: 24),
              // Department Distribution Chart
              _buildMonthlyLeaveTrends(leaveProvider.leaves),
              SizedBox(height: 24),
              _buildDepartmentChart(employeeProvider.employees),
              // Monthly Leave Trends
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveStatusChart(List leaves) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final pending = leaves
        .where((l) => l.status.toLowerCase().trim() == 'pending')
        .length;
    final approved = leaves
        .where(
          (l) =>
              l.status.toLowerCase().trim() == 'approved' ||
              l.status.toLowerCase().trim().contains('approv'),
        )
        .length;
    final rejected = leaves
        .where(
          (l) =>
              l.status.toLowerCase().trim() == 'rejected' ||
              l.status.toLowerCase().trim() == 'declined' ||
              l.status.toLowerCase().trim().contains('reject'),
        )
        .length;

    if (pending + approved + rejected == 0) {
      return _buildEmptyChartCard(
        'Leave Status Distribution',
        'No leave data available',
      );
    }

    final total = pending + approved + rejected;
    final pendingPercent = (pending / total * 100);
    final approvedPercent = (approved / total * 100);
    final rejectedPercent = (rejected / total * 100);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leave Status Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: pending.toDouble(),
                          title: '${pendingPercent.toStringAsFixed(1)}%',
                          color: Colors.orange,
                          radius: 60,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: approved.toDouble(),
                          title: '${approvedPercent.toStringAsFixed(1)}%',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: rejected.toDouble(),
                          title: '${rejectedPercent.toStringAsFixed(1)}%',
                          color: Colors.red,
                          radius: 60,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Pending', Colors.orange, pending),
                    SizedBox(height: 12),
                    _buildLegendItem('Approved', Colors.green, approved),
                    SizedBox(height: 12),
                    _buildLegendItem('Rejected', Colors.red, rejected),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$count leaves',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentChart(List employees) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Group employees by department
    final Map<String, int> deptCount = {};
    for (var emp in employees) {
      final dept = emp.department ?? 'Unassigned';
      deptCount[dept] = (deptCount[dept] ?? 0) + 1;
    }

    if (deptCount.isEmpty) {
      return _buildEmptyChartCard(
        'Department Distribution',
        'No employee data available',
      );
    }

    final sortedEntries = deptCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDepartments = sortedEntries.take(6).toList();

    final maxCount = topDepartments.isNotEmpty
        ? topDepartments.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Distribution',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount.toDouble() * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < topDepartments.length) {
                          final dept = topDepartments[index].key;
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              dept.length > 10
                                  ? '${dept.substring(0, 10)}...'
                                  : dept,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: topDepartments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dept = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dept.value.toDouble(),
                        color: _getColorForIndex(index),
                        width: 20,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: topDepartments.asMap().entries.map((entry) {
              final index = entry.key;
              final dept = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForIndex(index),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${dept.key}: ${dept.value}',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyLeaveTrends(List leaves) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Group leaves by month
    final Map<String, int> monthlyLeaves = {};
    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM yyyy').format(date);
      monthlyLeaves[key] = 0;
    }

    for (var leave in leaves) {
      try {
        // leave.from is already a DateTime, no need to parse
        final leaveDate = leave.from;
        final key = DateFormat('MMM yyyy').format(leaveDate);
        if (monthlyLeaves.containsKey(key)) {
          monthlyLeaves[key] = (monthlyLeaves[key] ?? 0) + 1;
        }
      } catch (e) {
        // Skip invalid dates
      }
    }

    final entries = monthlyLeaves.entries.toList();
    final maxCount = entries.isNotEmpty
        ? entries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Leave Trends (Last 6 Months)',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCount > 0
                      ? (maxCount / 5).ceil().toDouble()
                      : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < entries.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              entries[index].key.split(' ')[0],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                minY: 0,
                maxY: maxCount.toDouble() * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: entries.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.value.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartCard(String title, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 20),
          Icon(
            Icons.bar_chart,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  Widget _buildManagementSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigationProvider = Provider.of<NavigationProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildManagementCard(
                'Holidays',
                Icons.celebration,
                Colors.purple,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminHolidays,
                  );
                },
              ),
              _buildManagementCard(
                'Departments',
                Icons.business,
                Colors.blue,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminDepartments,
                  );
                },
              ),
              _buildManagementCard(
                'Leave Types',
                Icons.event_busy,
                Colors.orange,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminLeaveTypes,
                  );
                },
              ),
              _buildManagementCard(
                'Payslips',
                Icons.receipt_long,
                Colors.green,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminPayslips,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
