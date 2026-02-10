import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/screens/employee_detail_screen.dart';
import 'package:quantum_dashboard/services/attendance_service.dart';
import 'package:quantum_dashboard/utils/excel_export_utils.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isExporting = false;
  List<Map<String, dynamic>> _attendanceData = [];
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late int _daysInMonth;
  String _searchQuery = "";

  // UI Constants
  final double _nameColumnWidth = 180.0;
  final double _dateColumnWidth = 45.0;
  final double _rowHeight = 56.0;
  final double _headerHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _updateDaysInMonth();

    // Linked Scroll Controllers logic
    _headerScrollController.addListener(() {
      if (_bodyScrollController.hasClients) {
        if (_bodyScrollController.offset != _headerScrollController.offset) {
          _bodyScrollController.jumpTo(_headerScrollController.offset);
        }
      }
    });

    _bodyScrollController.addListener(() {
      if (_headerScrollController.hasClients) {
        if (_headerScrollController.offset != _bodyScrollController.offset) {
          _headerScrollController.jumpTo(_bodyScrollController.offset);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateDaysInMonth() {
    _daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<EmployeeProvider>(
        context,
        listen: false,
      ).getAllEmployees();
      await _fetchAttendanceData();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Silent error or snackbar
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    try {
      final data = await _attendanceService.getAdminAttendance(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          _attendanceData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredData {
    if (_searchQuery.isEmpty) return _attendanceData;
    return _attendanceData.where((item) {
      final name = (item['employeeName'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _navigateToEmployeeDetail(String employeeName, String employeeId) {
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );

    Employee? employee;
    try {
      employee = employeeProvider.employees.firstWhere(
        (e) => e.id == employeeId || e.employeeId == employeeId,
      );
    } catch (e) {
      try {
        employee = employeeProvider.employees.firstWhere(
          (e) => e.fullName.toLowerCase() == employeeName.toLowerCase(),
        );
      } catch (_) {}
    }

    if (employee != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeeDetailScreen(employee: employee!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile not found for $employeeName'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          _buildControls(isDark, colorScheme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredData.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildTableStructure(isDark, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No attendance records.'
                : 'No employees found.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigationProvider = Provider.of<NavigationProvider>(
      context,
      listen: false,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              navigationProvider.setCurrentPage(NavigationPage.Dashboard);
            },
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Overview',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Track monthly attendance for all employees',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;

              if (isSmallScreen) {
                // Stack vertically on small screens
                return Column(
                  children: [
                    // Download Excel Button - Full width on small screens
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: _buildExportButton(colorScheme),
                    ),
                    const SizedBox(height: 12),
                    // Search bar - Full width
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.outline.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search employee...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Month and Year dropdowns - Side by side
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedMonth,
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(
                                  DateFormat(
                                    'MMM',
                                  ).format(DateTime(2024, index + 1)),
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMonth = val;
                                  _updateDaysInMonth();
                                });
                                _fetchAttendanceData();
                              }
                            },
                            isDark: isDark,
                            colorScheme: colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedYear,
                            items: List.generate(5, (index) {
                              final year = DateTime.now().year - index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedYear = val;
                                  _updateDaysInMonth();
                                });
                                _fetchAttendanceData();
                              }
                            },
                            isDark: isDark,
                            colorScheme: colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Horizontal layout for larger screens
              return Row(
                children: [
                  // Download Excel Button
                  _buildExportButton(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.outline.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search employee...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.5),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    value: _selectedMonth,
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          DateFormat('MMM').format(DateTime(2024, index + 1)),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMonth = val;
                          _updateDaysInMonth();
                        });
                        _fetchAttendanceData();
                      }
                    },
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 12),
                  _buildDropdown(
                    value: _selectedYear,
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedYear = val;
                          _updateDaysInMonth();
                        });
                        _fetchAttendanceData();
                      }
                    },
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            children: [
              _buildLegendItem(Icons.check_circle, Colors.green, "Present"),
              const SizedBox(width: 16),
              _buildLegendItem(
                Icons.access_time_filled,
                Colors.orange,
                "Half Day",
              ),
              const SizedBox(width: 16),
              _buildLegendItem(Icons.cancel, Colors.red, "Absent"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(
              alpha: isDark ? 0.15 : 0.08,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurface),
          dropdownColor: colorScheme.surfaceContainerHighest,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTableStructure(bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(
              alpha: isDark ? 0.15 : 0.08,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // STICKY HEADER
            _buildStickyHeader(colorScheme),

            // SCROLLABLE BODY
            Expanded(child: _buildTableBody(colorScheme, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(ColorScheme colorScheme) {
    return Container(
      height: _headerHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Fixed "Employee" Header
          Container(
            width: _nameColumnWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
              ),
            ),
            child: Text(
              'Employee',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ),

          // Scrollable Date Headers
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _headerScrollController,
                  scrollDirection: Axis.horizontal,
                  physics:
                      const ClampingScrollPhysics(), // Prevent bounce desync
                  child: Row(
                    children: List.generate(_daysInMonth, (index) {
                      final date = DateTime(
                        _selectedYear,
                        _selectedMonth,
                        index + 1,
                      );
                      final isWeekend =
                          date.weekday == DateTime.saturday ||
                          date.weekday == DateTime.sunday;

                      return Container(
                        width: _dateColumnWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isWeekend
                              ? colorScheme.error.withOpacity(0.05)
                              : null,
                          border: Border(
                            right: BorderSide(
                              color: colorScheme.outline.withOpacity(0.05),
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (index + 1).toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isWeekend
                                    ? colorScheme.error
                                    : colorScheme.onSurface,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              DateFormat('E').format(date).substring(0, 1),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                color: isWeekend
                                    ? colorScheme.error.withOpacity(0.7)
                                    : colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                // Header Gradient/Fade on right to show continuity
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          colorScheme.surfaceContainerHighest.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableBody(ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const ClampingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIXED LEFT COLUMN (NAMES)
          SizedBox(
            width: _nameColumnWidth,
            child: Column(
              children: List.generate(_filteredData.length, (index) {
                final employeeData = _filteredData[index];
                final empName = employeeData['employeeName'] ?? 'Unknown';
                final empId =
                    employeeData['employeeId'] ??
                    employeeData['_id']?.toString() ??
                    '';
                final isEven = index % 2 == 0;

                return InkWell(
                  onTap: () => _navigateToEmployeeDetail(empName, empId),
                  child: Container(
                    height: _rowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isEven
                          ? Colors.transparent
                          : colorScheme.surface.withOpacity(0.5),
                      border: Border(
                        bottom: BorderSide(
                          color: colorScheme.outline.withOpacity(0.05),
                        ),
                        right: BorderSide(
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            empName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // SCROLLABLE RIGHT BLOCK (DATA)
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _bodyScrollController,
                  scrollDirection: Axis.horizontal,
                  physics:
                      const ClampingScrollPhysics(), // Prevent bounce desync
                  child: Column(
                    children: List.generate(_filteredData.length, (index) {
                      final employeeData = _filteredData[index];
                      final isEven = index % 2 == 0;

                      return Container(
                        height: _rowHeight,
                        decoration: BoxDecoration(
                          color: isEven
                              ? Colors.transparent
                              : colorScheme.surface.withOpacity(0.5),
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline.withOpacity(0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          children: List.generate(_daysInMonth, (dayIndex) {
                            final day = dayIndex + 1;
                            final dateStr =
                                '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

                            final List<dynamic> attendanceRecords =
                                employeeData['attendance'] ?? [];
                            final record = attendanceRecords.firstWhere(
                              (r) => r['date'] == dateStr,
                              orElse: () => null,
                            );

                            final date = DateTime(
                              _selectedYear,
                              _selectedMonth,
                              day,
                            );
                            final isWeekend =
                                date.weekday == DateTime.saturday ||
                                date.weekday == DateTime.sunday;

                            return Container(
                              width: _dateColumnWidth,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isWeekend
                                    ? colorScheme.error.withOpacity(0.02)
                                    : null,
                                border: Border(
                                  right: BorderSide(
                                    color: colorScheme.outline.withOpacity(
                                      0.05,
                                    ),
                                  ),
                                ),
                              ),
                              child: _buildStatusIcon(record),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
                // Visual Cue for Scrolling (Right Shadow)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 30,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            isDark
                                ? Colors.black.withOpacity(0.4)
                                : Colors.white.withOpacity(0.8),
                            isDark
                                ? Colors.black.withOpacity(0.0)
                                : Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(Map<String, dynamic>? record) {
    if (record == null) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      );
    }

    final status = record['attendanceStatus'];

    if (status == 'Present') {
      return Icon(Icons.check_circle, color: Colors.green, size: 20);
    } else if (status == 'Half Day') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Text(
          'H',
          style: GoogleFonts.poppins(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      );
    } else if (status == 'Absent') {
      return Icon(Icons.cancel, color: Colors.red.withOpacity(0.7), size: 20);
    }

    return SizedBox();
  }

  Widget _buildExportButton(ColorScheme colorScheme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isExporting || _attendanceData.isEmpty
              ? null
              : _exportToExcel,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isExporting)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                else
                  Icon(Icons.download, color: colorScheme.onPrimary, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _isExporting ? 'Exporting...' : 'Export Excel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    if (_attendanceData.isEmpty) {
      SnackbarUtils.showWarning(context, 'No attendance data to export');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final filePath = await ExcelExportUtils.exportAttendanceToExcel(
        attendanceData: _attendanceData,
        month: _selectedMonth,
        year: _selectedYear,
        context: context,
      );

      if (mounted) {
        setState(() => _isExporting = false);
        if (filePath != null) {
          SnackbarUtils.showSuccess(
            context,
            'Attendance sheet exported successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        SnackbarUtils.showError(
          context,
          'Failed to export attendance: ${e.toString()}',
        );
      }
    }
  }
}
