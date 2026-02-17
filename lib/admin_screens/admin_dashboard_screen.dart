import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/widgets/notification_icon_widget.dart';
import 'package:quantum_dashboard/screens/send_notification_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/services/department_service.dart';
import 'package:quantum_dashboard/utils/responsive_utils.dart';
import 'package:quantum_dashboard/admin_screens/admin_compoff_screen.dart';

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
            SizedBox(
              height: (ResponsiveUtils.spacing(context, base: 80) + 40)
                  .clamp(100, 140),
            ), // Extra padding for nav bar
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

    return Container(
      padding: ResponsiveUtils.padding(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $firstName',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Admin Dashboard Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Spacer(),
          SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SendNotificationScreen(),
                ),
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
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, child) {
        final employeeCount = employeeProvider.employees.length;
        final departmentCount = _departments.length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 600;
                  final crossAxisCount = isSmall ? 2 : 3;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isSmall ? 1.1 : 1.3, // Increased height
                    children: [
                      _buildStatCard(
                        'Total Employees',
                        employeeCount.toString(),
                        Icons.people_alt_rounded,
                        const Color(0xFF6366F1),
                      ),
                      _buildStatCard(
                        'Departments',
                        departmentCount.toString(),
                        Icons.account_tree_rounded,
                        const Color(0xFFEC4899),
                      ),
                      // _buildStatCard(
                      //   'Pending Leaves',
                      //   pendingLeaves.toString(),
                      //   Icons.pending_actions_rounded,
                      //   const Color(0xFFF59E0B),
                      // ),
                    ],
                  );
                },
              ),
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : colorScheme.outline.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative background element
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Better alignment
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.green.withOpacity(0.5),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  // Use expanded to allow text to fit but not overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FittedBox(
                        // Ensure large numbers scale down if needed
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.5),
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analytics & Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Live Data',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMonthlyLeaveTrends(leaveProvider.leaves),
              const SizedBox(height: 20),
              _buildDepartmentChart(employeeProvider.employees),
              const SizedBox(height: 20),
              _buildLeaveStatusChart(leaveProvider.leaves),
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
        .where(
          (l) =>
              l.status.toLowerCase().trim() == 'pending' ||
              l.status.toLowerCase().trim() == 'new',
        )
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
        'Leave Insights',
        'Insufficient data for leave distribution',
      );
    }

    final total = pending + approved + rejected;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Status',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              height: 1,
                            ),
                          ),
                          Text(
                            'TOTAL',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.4),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: pending.toDouble(),
                              color: const Color(0xFFF59E0B),
                              radius: 20,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: approved.toDouble(),
                              color: const Color(0xFF10B981),
                              radius: 20,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: rejected.toDouble(),
                              color: const Color(0xFFEF4444),
                              radius: 20,
                              showTitle: false,
                            ),
                          ],
                          sectionsSpace: 4,
                          centerSpaceRadius: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModernLegendItem(
                      'Pending',
                      const Color(0xFFF59E0B),
                      pending,
                      total,
                    ),
                    const SizedBox(height: 12),
                    _buildModernLegendItem(
                      'Approved',
                      const Color(0xFF10B981),
                      approved,
                      total,
                    ),
                    const SizedBox(height: 12),
                    _buildModernLegendItem(
                      'Rejected',
                      const Color(0xFFEF4444),
                      rejected,
                      total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernLegendItem(
    String label,
    Color color,
    int count,
    int total,
  ) {
    final percent = total > 0 ? (count / total * 100).toInt() : 0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                '$count Requests',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
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

    final Map<String, int> deptCount = {};
    for (var emp in employees) {
      final dept = emp.department ?? 'Unassigned';
      deptCount[dept] = (deptCount[dept] ?? 0) + 1;
    }

    if (deptCount.isEmpty) {
      return _buildEmptyChartCard(
        'Departments',
        'No department data available',
      );
    }

    final sortedEntries = deptCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDepartments = sortedEntries.take(5).toList();
    final maxCount = topDepartments.isNotEmpty
        ? topDepartments.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Department Mix',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.pie_chart_outline_rounded,
                size: 18,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: maxCount.toDouble() * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colorScheme.surface,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: BorderSide(
                      color: colorScheme.outline.withOpacity(0.1),
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${topDepartments[groupIndex].key}\n',
                        GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} Employees',
                            style: GoogleFonts.poppins(
                              color: colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
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
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              dept
                                  .substring(
                                    0,
                                    dept.length > 3 ? 3 : dept.length,
                                  )
                                  .toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: topDepartments.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            _getColorForIndex(entry.key),
                            _getColorForIndex(entry.key).withOpacity(0.7),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: BorderRadius.circular(20),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxCount.toDouble() * 1.1,
                          color: colorScheme.primary.withOpacity(0.05),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend for departments
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: topDepartments.asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getColorForIndex(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.value.key,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.5),
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

    final Map<String, int> monthlyLeaves = {};
    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(date);
      monthlyLeaves[key] = 0;
    }

    for (var leave in leaves) {
      try {
        final key = DateFormat('MMM').format(leave.from);
        if (monthlyLeaves.containsKey(key)) {
          monthlyLeaves[key] = (monthlyLeaves[key] ?? 0) + 1;
        }
      } catch (e) {}
    }

    final entries = monthlyLeaves.entries.toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Trends',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Icon(
                Icons.auto_graph_rounded,
                size: 18,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
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
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              entries[index].key.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: entries
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            e.value.value.toDouble(),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 5,
                            color: colorScheme.primary,
                            strokeWidth: 2.5,
                            strokeColor: colorScheme.surface,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.2),
                          colorScheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
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

    final List<Map<String, dynamic>> managementItems = [
      {
        'title': 'Attendance',
        'subtitle': 'Staff clock-in records',
        'icon': Icons.how_to_reg_rounded,
        'color': Colors.redAccent,
        'page': NavigationPage.AdminAttendance,
      },
      {
        'title': 'Holidays',
        'subtitle': 'Manage company holidays',
        'icon': Icons.celebration_rounded,
        'color': Colors.purple,
        'page': NavigationPage.AdminHolidays,
      },
      {
        'title': 'Payslips',
        'subtitle': 'Payroll & distribution',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.green,
        'page': NavigationPage.AdminPayslips,
      },
      {
        'title': 'Locations',
        'subtitle': 'Office & remote sites',
        'icon': Icons.map_rounded,
        'color': Colors.indigo,
        'page': NavigationPage.AdminLocations,
      },
      {
        'title': 'Mobile Access',
        'subtitle': 'App device permission',
        'icon': Icons.phonelink_setup_rounded,
        'color': Colors.teal,
        'page': NavigationPage.AdminMobileAccess,
      },
      {
        'title': 'Compoff',
        'subtitle': 'Grant compoff credits',
        'icon': Icons.event_available,
        'color': Colors.deepOrange,
        'page': NavigationPage.AdminCompoff,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Management',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
            ),
            itemCount: managementItems.length,
            itemBuilder: (context, index) {
              final item = managementItems[index];
              final page = item['page'] as NavigationPage?;
              final VoidCallback onTap = page == NavigationPage.AdminCompoff
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminCompoffScreen(),
                        ),
                      )
                  : () => navigationProvider.setCurrentPage(page!);
              return _buildManagementCard(
                item['title'],
                item['subtitle'],
                item['icon'],
                item['color'],
                onTap,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.5),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
