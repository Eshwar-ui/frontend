import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/services/attendance_service.dart';
import 'package:quantum_dashboard/services/attendance_settings_service.dart';
import 'package:quantum_dashboard/services/location_service.dart';
import 'package:quantum_dashboard/models/company_location_model.dart';
import 'package:quantum_dashboard/models/employee_location_model.dart';
// import 'package:quantum_dashboard/services/leave_service.dart';
import 'package:quantum_dashboard/models/attendance_model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/providers/notification_settings_provider.dart';
import 'package:quantum_dashboard/widgets/notification_icon_widget.dart';
import 'package:quantum_dashboard/screens/compoff_wallet_screen.dart';
import 'package:quantum_dashboard/utils/responsive_utils.dart';
import 'package:geolocator/geolocator.dart';

class new_dashboard extends StatefulWidget {
  const new_dashboard({super.key});

  @override
  State<new_dashboard> createState() => _new_dashboardState();
}

class _new_dashboardState extends State<new_dashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  final AttendanceSettingsService _attendanceSettingsService =
      AttendanceSettingsService();

  // Company locations loaded from backend
  List<CompanyLocation> _companyLocations = [];
  // Employee-specific WFH locations loaded from backend
  List<EmployeeLocation> _employeeLocations = [];
  bool _isLoadingLocations = false;
  String? _locationError;
  bool _locationPunchInEnabled = true;
  bool _isSettingsLoading = false;

  // Attendance data
  bool _isLoading = true;
  Attendance? _todayAttendance;
  List<Attendance> _todayPunches = [];
  double _totalWorkTime = 0.0;
  double _totalBreakTime = 0.0;
  Timer? _workTimeTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // Update clock every second so the displayed time stays current
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Wait for the widget to be fully built before accessing context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceSettings();
      _loadAllLocations();
      _loadAttendanceData();
      _calculateTotalWorkTime(_todayPunches);
      _calculateTotalBreakTime(_todayPunches);
      // Start notification polling if enabled
      final settingsProvider = Provider.of<NotificationSettingsProvider>(
        context,
        listen: false,
      );
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      if (settingsProvider.notificationsEnabled) {
        notificationProvider.startPolling(
          interval: Duration(seconds: settingsProvider.pollingInterval),
        );
      }
    });
  }

  Future<void> _loadAttendanceSettings() async {
    if (!mounted) return;
    setState(() => _isSettingsLoading = true);
    try {
      final enabled = await _attendanceSettingsService
          .getLocationPunchInEnabled();
      if (mounted) {
        setState(() {
          _locationPunchInEnabled = enabled;
          _isSettingsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSettingsLoading = false);
      }
    }
  }

  Future<void> _loadAllLocations() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      // Load company locations
      final companyLocations = await _locationService.getCompanyLocations();

      // Load employee-specific locations
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      List<EmployeeLocation> employeeLocations = [];

      if (user != null) {
        try {
          employeeLocations = await _locationService.getEmployeeLocations(
            user.employeeId,
          );
        } catch (e) {
          debugPrint('⚠️ Error loading employee locations: $e');
          // Continue even if employee locations fail to load
        }
      }

      if (mounted) {
        setState(() {
          _companyLocations = companyLocations;
          _employeeLocations = employeeLocations;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading locations: $e');
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocations = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _workTimeTimer?.cancel();
    _clockTimer?.cancel();
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

  void _showLocationSelectionSheet() {
    if (_isLoadingLocations) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading locations...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final totalLocations = _companyLocations.length + _employeeLocations.length;
    if (totalLocations == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _locationError != null
                ? 'Error loading locations: $_locationError'
                : 'No locations available. Please contact your administrator.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final padding = ResponsiveUtils.padding(context);
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 8),
                child: Text(
                  'Select Your Location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Company Locations Section
                    if (_companyLocations.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          'Company Locations',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      ..._companyLocations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final location = entry.value;
                        return Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.business,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              title: Text(
                                location.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.address,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _verifyLocationAndPunch(
                                  location.name,
                                  location.latitude,
                                  location.longitude,
                                );
                              },
                            ),
                            if (index < _companyLocations.length - 1 ||
                                _employeeLocations.isNotEmpty)
                              Divider(
                                color: theme.dividerColor.withOpacity(0.1),
                              ),
                          ],
                        );
                      }),
                    ],

                    // Employee WFH Locations Section
                    if (_employeeLocations.isNotEmpty) ...[
                      if (_companyLocations.isNotEmpty) SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          'Work From Home Locations',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      ..._employeeLocations.asMap().entries.map((entry) {
                        final index = entry.key;
                        final location = entry.value;
                        return Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.home_work,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              title: Text(
                                location.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.address,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _verifyLocationAndPunch(
                                  location.name,
                                  location.latitude,
                                  location.longitude,
                                );
                              },
                            ),
                            if (index < _employeeLocations.length - 1)
                              Divider(
                                color: theme.dividerColor.withOpacity(0.1),
                              ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyLocationAndPunch(
    String locationName,
    double targetLatitude,
    double targetLongitude,
  ) async {
    // Check if widget is still mounted before accessing context
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    // 1. Check Location Services
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location services are disabled. Please enable them.',
            ),
            action: SnackBarAction(
              label: 'Enable',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return;
    }

    // 2. Check Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Location permission denied')));
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission permanently denied')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verifying location...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    Position? position;

    // 3. Fast Path: Try Last Known Position (Latency Reduction)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final now = DateTime.now();
        // On some platforms/versions timestamp might be null, handle that safely if needed,
        // but standard Geolocator Position usually has it.
        // Check age of location
        final difference = now.difference(lastKnown.timestamp);
        // Use cached location if it's less than 2 minutes old
        if (difference.inMinutes < 2) {
          debugPrint(
            "🚀 Using cached location (Age: ${difference.inSeconds}s)",
          );
          position = lastKnown;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error getting last known position: $e");
      // Continue to fetch fresh location
    }

    // 4. Slow Path: Get Fresh Position (if cached is missing or stale)
    if (position == null) {
      try {
        debugPrint("📡 Fetching fresh location...");
        // Set a timeout to prevent infinite hanging
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        if (mounted) {
          String errorMsg = 'Error getting location: $e';
          if (e is TimeoutException) {
            errorMsg = 'Location request timed out. Please ensure GPS is on.';
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
        return;
      }
    }

    // Position is assigned at this point
    final currentPosition = position;

    // Calculate distance
    double distanceInMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      targetLatitude,
      targetLongitude,
    );

    debugPrint(
      '📍 User Location: ${currentPosition.latitude}, ${currentPosition.longitude}',
    );
    debugPrint('🏢 Target Location: $targetLatitude, $targetLongitude');
    debugPrint('📏 Distance: ${distanceInMeters.toStringAsFixed(2)} meters');

    if (distanceInMeters > 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You are ${distanceInMeters.toStringAsFixed(0)}m away from $locationName. Must be within 500m.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Proceed to punch
    await _performPunch(currentPosition.latitude, currentPosition.longitude);
  }

  Future<void> _performPunch(double? latitude, double? longitude) async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final isPunchedIn = _todayAttendance?.isPunchedIn ?? false;

    // Optimistically update the UI immediately for better UX
    if (mounted) {
      setState(() {
        if (isPunchedIn) {
          // Punching out - set punchOut time (but keep the attendance object)
          if (_todayAttendance != null) {
            _isLoading = true;
          }
        } else {
          // Punching in - create a temporary attendance record
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
        await _attendanceService.punchOut(
          user.employeeId,
          user.fullName,
          latitude ?? 0.0,
          longitude ?? 0.0,
        );
        debugPrint('✅ Punched out successfully!');
      } else {
        // Punch In
        debugPrint('⏰ Punching in...');
        await _attendanceService.punchIn(
          user.employeeId,
          user.fullName,
          latitude ?? 0.0,
          longitude ?? 0.0,
        );
        debugPrint('✅ Punched in successfully!');
      }

      // Check if still mounted after async operation
      if (!mounted) return;

      // Reload attendance data
      await _loadAttendanceData();

      // Show success message
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

      // On error, reload the actual data
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

  Future<void> _handlePunchInOut() async {
    if (_isSettingsLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading attendance settings...')),
      );
      return;
    }

    if (_locationPunchInEnabled) {
      _showLocationSelectionSheet();
      return;
    }

    await _performPunch(null, null);
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
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 16)),
                  Text(
                    'Loading attendance data...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                  SizedBox(height: ResponsiveUtils.spacing(context, base: 24)),
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
                  SizedBox(
                    height: (ResponsiveUtils.spacing(context, base: 80) + 40)
                        .clamp(100, 140),
                  ), // Extra padding for nav bar
                ],
              ),
            ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedTime,
              style: GoogleFonts.poppins(
                fontSize: 60,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_monthToString(month)} $date $year - ${_weekdayToString(DateTime.now().weekday)}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
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
          // errorBuilder: (context, error, stackTrace) {
          //   // Show initial if image fails to load
          //   return Text(
          //     initial,
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 20,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   );
          // },
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
              SizedBox(
                width: 220,
                // Adjust as needed or use LayoutBuilder for more dynamic width
                child: Text(
                  'Hey $firstName',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(
                '${getGreeting()}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Spacer(),
          // IconButton(
          //   icon: const Icon(Icons.account_balance_wallet_outlined),
          //   tooltip: 'Compoff Wallet',
          //   onPressed: () {
          //     Navigator.of(context).push(
          //       MaterialPageRoute(
          //         builder: (context) => const CompoffWalletScreen(),
          //       ),
          //     );
          //   },
          // ),
          NotificationIconWidget(),
          SizedBox(width: 12),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme
                  .surface // very dark, elegant background
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHistoryItem(
              icon: Icons.login,
              color: colorScheme.primary,
              timeText: formatTime(firstPunchInTime),
              labelText: 'Punch In',
              isDark: isDark,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 24),
            _buildHistoryItem(
              icon: Icons.access_time,
              color: colorScheme.primary,
              timeText: formatDuration(totalWorkDuration),
              labelText: 'Work time',
              isDark: isDark,
              colorScheme: colorScheme,
            ),
            SizedBox(width: 24),
            _buildHistoryItem(
              icon: Icons.free_breakfast,
              color: colorScheme.primary,
              timeText: formatDuration(totalBreakDuration),
              labelText: 'Break time',
              isDark: isDark,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required IconData icon,
    required Color color,
    required String timeText,
    required String labelText,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primary.withOpacity(0.15)
                : colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        SizedBox(height: 8),
        Text(
          timeText,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          labelText,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ],
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
        color: isDark ? colorScheme.surface : colorScheme.surface,
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
