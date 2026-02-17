import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/compoff_credit_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/compoff_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminCompoffScreen extends StatefulWidget {
  const AdminCompoffScreen({super.key});

  @override
  State<AdminCompoffScreen> createState() => _AdminCompoffScreenState();
}

enum _CompoffStatusFilter { all, available, used, expired }

class _AdminCompoffScreenState extends State<AdminCompoffScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _eligible = [];
  String? _earnedSource;
  final Set<String> _selectedEmployeeIds = {};
  bool _isLoading = false;
  bool _includeAllEmployees = false;

  // Tabs: Grant / Monitor
  late TabController _tabController;

  // Monitor tab state
  String? _monitorEmployeeId;
  List<CompoffCredit> _monitorCredits = [];
  bool _monitorIsLoading = false;
  String? _monitorError;
  _CompoffStatusFilter _monitorStatusFilter = _CompoffStatusFilter.all;
  bool _monitorOnlyExpiredUnused = false;

  // Employee search for monitor tab
  final TextEditingController _monitorEmployeeSearchController =
      TextEditingController();
  final FocusNode _monitorEmployeeSearchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _monitorEmployeeSearchFocusNode.addListener(_onMonitorSearchChange);
    _monitorEmployeeSearchController.addListener(_onMonitorSearchChange);
    _loadEligible();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _monitorEmployeeSearchFocusNode.removeListener(_onMonitorSearchChange);
    _monitorEmployeeSearchFocusNode.dispose();
    _monitorEmployeeSearchController.removeListener(_onMonitorSearchChange);
    _monitorEmployeeSearchController.dispose();
    super.dispose();
  }

  void _onMonitorSearchChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadEligible() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<CompoffProvider>(context, listen: false);
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final result = await provider.fetchEligible(
        date,
        includeAllEmployees: _includeAllEmployees,
      );
      final eligible = result['eligible'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _earnedSource = result['earnedSource'];
          _eligible = eligible.cast<Map<String, dynamic>>();
          _selectedEmployeeIds.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to load eligibility: ${e.toString()}',
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectAll() {
    setState(() {
      for (final item in _eligible) {
        final id = item['employeeId'] as String?;
        if (id != null && id.isNotEmpty) _selectedEmployeeIds.add(id);
      }
    });
  }

  void _deselectAll() {
    setState(() => _selectedEmployeeIds.clear());
  }

  Future<void> _grantSelected() async {
    if (_selectedEmployeeIds.isEmpty) return;

    final provider = Provider.of<CompoffProvider>(context, listen: false);
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final result = await provider.grantCompoff(
        employeeIds: _selectedEmployeeIds.toList(),
        earnedDate: date,
        earnedSource: _earnedSource ?? '',
        allowWithoutAttendance: _includeAllEmployees,
      );

      final granted = result['granted'] as int? ?? 0;
      final skipped = result['skipped'] as List<dynamic>? ?? [];

      if (!mounted) return;
      await _loadEligible();

      if (skipped.isNotEmpty) {
        showDialog<void>(
          context: context,
          builder: (context) => _GrantResultDialog(
            granted: granted,
            skipped: skipped,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        );
      } else {
        SnackbarUtils.showSuccess(
          context,
          'Granted $granted compoff credit(s).',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Failed to grant compoff: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      await _loadEligible();
    }
  }

  Future<void> _loadMonitorCredits(String employeeId) async {
    setState(() {
      _monitorIsLoading = true;
      _monitorError = null;
    });

    try {
      final provider = Provider.of<CompoffProvider>(context, listen: false);
      final credits = await provider.fetchEmployeeCredits(employeeId);
      if (!mounted) return;
      setState(() {
        _monitorCredits = credits;
        _monitorIsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _monitorError = e.toString();
        _monitorIsLoading = false;
        _monitorCredits = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dateText = DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Compoff Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadEligible,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          indicatorWeight: 3,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withOpacity(0.8),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Grant'),
            Tab(text: 'Monitor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrantTab(colorScheme, isDark, dateText),
          _buildMonitorTab(colorScheme, isDark),
        ],
      ),
    );
  }

  Widget _buildGrantTab(ColorScheme colorScheme, bool isDark, String dateText) {
    return Column(
      children: [
        // Filter / info card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available,
                    size: 22,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eligibility date',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          dateText,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _isLoading ? null : _pickDate,
                    icon: Icon(Icons.calendar_month, size: 20),
                    label: Text(
                      'Change date',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (_earnedSource == null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: colorScheme.error,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No holiday or weekly off on this date. Select a holiday or weekly off to grant compoff.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                SizedBox(height: 12),
                Text(
                  'Earned source: ${_earnedSource!.replaceAll('_', ' ')}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _includeAllEmployees
                            ? 'Include all employees (manual grant)'
                            : 'Punched-in only',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _includeAllEmployees,
                      onChanged: (value) {
                        setState(() => _includeAllEmployees = value);
                        _loadEligible();
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      SizedBox(height: 16),
                      Text(
                        'Loading eligible employees...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : _eligible.isEmpty
              ? _buildEmptyState(colorScheme)
              : _buildEligibleList(colorScheme, isDark),
        ),

        // Grant button bar — responsive: row on wide, wrap/stack on narrow
        if (_eligible.isNotEmpty && _earnedSource != null)
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const breakpoint = 480.0;
                  final isNarrow = constraints.maxWidth < breakpoint;

                  if (isNarrow) {
                    // Stack vertically on small screens; full-width buttons
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selectAll,
                                icon: Icon(
                                  Icons.check_box,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                label: Text(
                                  'Select all',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                  side: BorderSide(color: colorScheme.outline),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _deselectAll,
                                icon: Icon(
                                  Icons.check_box_outlined,
                                  size: 20,
                                  color: colorScheme.onSurface,
                                ),
                                label: Text(
                                  'Deselect all',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.onSurface,
                                  side: BorderSide(color: colorScheme.outline),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _selectedEmployeeIds.isEmpty
                              ? null
                              : _grantSelected,
                          icon: Icon(Icons.add_task, size: 22),
                          label: Text(
                            'Grant (${_selectedEmployeeIds.length})',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    );
                  }

                  // Wide: single row with flexible outlined buttons
                  return Row(
                    children: [
                      Flexible(
                        child: OutlinedButton.icon(
                          onPressed: _selectAll,
                          icon: Icon(
                            Icons.check_box,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Select all',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.outline),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: OutlinedButton.icon(
                          onPressed: _deselectAll,
                          icon: Icon(
                            Icons.check_box_outlined,
                            size: 20,
                            color: colorScheme.onSurface,
                          ),
                          label: Text(
                            'Deselect all',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(color: colorScheme.outline),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _selectedEmployeeIds.isEmpty
                              ? null
                              : _grantSelected,
                          icon: Icon(Icons.add_task, size: 22),
                          label: Text(
                            'Grant (${_selectedEmployeeIds.length})',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _earnedSource == null
                  ? Icons.calendar_today
                  : Icons.people_outline,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 16),
            Text(
              _earnedSource == null
                  ? 'Select a holiday or weekly off date'
                  : 'No eligible employees found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              _earnedSource == null
                  ? 'Tap "Change date" above to pick another date.'
                  : 'Employees who punched in on this date will appear here.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibleList(ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _eligible.length,
      itemBuilder: (context, index) {
        final item = _eligible[index];
        final id = item['employeeId'] as String? ?? '';
        final name = item['employeeName'] as String? ?? 'Unknown';
        final selected = _selectedEmployeeIds.contains(id);

        return Card(
          margin: EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surface,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedEmployeeIds.remove(id);
                } else {
                  _selectedEmployeeIds.add(id);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Checkbox(
                    value: selected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedEmployeeIds.add(id);
                        } else {
                          _selectedEmployeeIds.remove(id);
                        }
                      });
                    },
                    activeColor: colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 2),
                        Text(
                          id,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? colorScheme.primary : colorScheme.outline,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- Monitor tab ----------------

  List<Employee> _monitorFilteredEmployees(
    EmployeeProvider employeeProvider,
    String query,
  ) {
    if (query.isEmpty) return employeeProvider.employees;
    final q = query.toLowerCase();
    return employeeProvider.employees.where((e) {
      final name = e.fullName.toLowerCase();
      final id = e.employeeId.toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  Widget _buildMonitorEmployeeSearch(
    ColorScheme colorScheme,
    EmployeeProvider employeeProvider,
    bool isDark,
  ) {
    final query = _monitorEmployeeSearchController.text.trim();
    final showList = _monitorEmployeeSearchFocusNode.hasFocus;
    final filtered = _monitorFilteredEmployees(employeeProvider, query);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _monitorEmployeeSearchController,
          focusNode: _monitorEmployeeSearchFocusNode,
          decoration: InputDecoration(
            labelText: 'Employee',
            hintText: 'Search by name or ID...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
            suffixIcon: _monitorEmployeeId != null
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _monitorEmployeeId = null;
                        _monitorCredits = [];
                        _monitorEmployeeSearchController.clear();
                      });
                    },
                    tooltip: 'Clear selection',
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          onChanged: (_) {
            setState(() {});
          },
          onTap: () {
            // Do not clear current selection automatically; let user decide via X button.
          },
        ),
        if (showList) ...[
          SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No employees match \"$query\"',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((emp) {
                      final isSelected = _monitorEmployeeId == emp.employeeId;
                      return ListTile(
                        leading: Icon(
                          Icons.person_outline,
                          size: 22,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        title: Text(
                          '${emp.employeeId} - ${emp.fullName}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          setState(() {
                            _monitorEmployeeId = emp.employeeId;
                            _monitorEmployeeSearchController.text =
                                '${emp.employeeId} - ${emp.fullName}';
                          });
                          _monitorEmployeeSearchFocusNode.unfocus();
                          _loadMonitorCredits(emp.employeeId);
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMonitorTab(ColorScheme colorScheme, bool isDark) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonitorEmployeeSearch(colorScheme, employeeProvider, isDark),
          SizedBox(height: 12),
          if (_monitorEmployeeId == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Select an employee',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Search above to view their compoff credits.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_monitorIsLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading credits...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_monitorError != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Error loading credits',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                      ),
                    ),
                    SizedBox(height: 6),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _monitorError!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _monitorEmployeeId == null
                          ? null
                          : () => _loadMonitorCredits(_monitorEmployeeId!),
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(child: _buildMonitorContent(colorScheme, isDark)),
        ],
      ),
    );
  }

  Widget _buildMonitorContent(ColorScheme colorScheme, bool isDark) {
    // Summary counts
    final availableCount = _monitorCredits
        .where((c) => c.status == 'AVAILABLE')
        .length;
    final usedCount = _monitorCredits.where((c) => c.status == 'USED').length;
    final expiredCount = _monitorCredits
        .where((c) => c.status == 'EXPIRED')
        .length;

    // Filters row
    Widget buildFilterChip(String label, _CompoffStatusFilter value) {
      final selected = _monitorStatusFilter == value;
      return ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: selected,
        onSelected: (_) {
          setState(() => _monitorStatusFilter = value);
        },
      );
    }

    List<CompoffCredit> filtered = _monitorCredits.where((credit) {
      switch (_monitorStatusFilter) {
        case _CompoffStatusFilter.available:
          if (credit.status != 'AVAILABLE') return false;
          break;
        case _CompoffStatusFilter.used:
          if (credit.status != 'USED') return false;
          break;
        case _CompoffStatusFilter.expired:
          if (credit.status != 'EXPIRED') return false;
          break;
        case _CompoffStatusFilter.all:
          break;
      }

      if (_monitorOnlyExpiredUnused) {
        if (!(credit.status == 'EXPIRED' && credit.usedAt == null)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chips
        Row(
          children: [
            _buildSummaryChip(
              colorScheme,
              count: availableCount,
              label: 'Available',
              color: colorScheme.primary,
              icon: Icons.check_circle_outline,
            ),
            SizedBox(width: 8),
            _buildSummaryChip(
              colorScheme,
              count: usedCount,
              label: 'Used',
              color: colorScheme.tertiary,
              icon: Icons.history,
            ),
            SizedBox(width: 8),
            _buildSummaryChip(
              colorScheme,
              count: expiredCount,
              label: 'Expired',
              color: colorScheme.error,
              icon: Icons.schedule,
            ),
          ],
        ),
        SizedBox(height: 12),
        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              buildFilterChip('All', _CompoffStatusFilter.all),
              SizedBox(width: 8),
              buildFilterChip('Available', _CompoffStatusFilter.available),
              SizedBox(width: 8),
              buildFilterChip('Used', _CompoffStatusFilter.used),
              SizedBox(width: 8),
              buildFilterChip('Expired', _CompoffStatusFilter.expired),
            ],
          ),
        ),
        Row(
          children: [
            Switch(
              value: _monitorOnlyExpiredUnused,
              onChanged: (val) {
                setState(() => _monitorOnlyExpiredUnused = val);
              },
            ),
            Expanded(
              child: Text(
                'Show only expired without use',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: colorScheme.onSurface.withOpacity(0.35),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No credits match the current filters',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Try changing the status filter or turning off the \"Show only expired without use\" toggle.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _buildMonitorCreditList(filtered, colorScheme, isDark),
        ),
      ],
    );
  }

  Widget _buildSummaryChip(
    ColorScheme colorScheme, {
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorCreditList(
    List<CompoffCredit> credits,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 8),
      itemCount: credits.length,
      itemBuilder: (context, index) {
        final credit = credits[index];
        final daysLeft = credit.expiryDate.difference(DateTime.now()).inDays;
        final isExpiredUnused =
            credit.status == 'EXPIRED' && credit.usedAt == null;
        final isWarning =
            credit.status == 'AVAILABLE' && daysLeft >= 0 && daysLeft <= 7;

        Color borderColor = Colors.transparent;
        if (isExpiredUnused) {
          borderColor = colorScheme.error;
        } else if (isWarning) {
          borderColor = colorScheme.tertiary;
        }

        return Card(
          margin: EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: borderColor == Colors.transparent
                  ? Colors.transparent
                  : borderColor.withOpacity(0.8),
              width: borderColor == Colors.transparent ? 0.8 : 1.2,
            ),
          ),
          color: isDark
              ? colorScheme.surfaceContainerHighest
              : colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.event_available,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  credit.earnedSource.replaceAll('_', ' '),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 8),
                              _buildStatusChip(
                                context,
                                credit.status,
                                isWarning,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Earned: ${DateFormat('dd MMM yyyy').format(credit.earnedDate)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.75),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Expires: ${DateFormat('dd MMM yyyy').format(credit.expiryDate)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.75),
                            ),
                          ),
                          if (credit.grantedBy.isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text(
                              'Granted by: ${credit.grantedBy}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Text(
                            'View details',
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                        // TODO: Add actions like expire/extend/delete when backend supports them.
                      ],
                      onSelected: (value) {
                        if (value == 'details') {
                          _showCreditDetailsDialog(credit, colorScheme);
                        }
                      },
                    ),
                  ],
                ),
                if (isExpiredUnused) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Expired without being used',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (isWarning) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Expiring in $daysLeft day(s)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreditDetailsDialog(CompoffCredit credit, ColorScheme colorScheme) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Compoff details',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Employee ID', credit.employeeId, colorScheme),
                _buildDetailRow(
                  'Earned date',
                  DateFormat('dd MMM yyyy').format(credit.earnedDate),
                  colorScheme,
                ),
                _buildDetailRow(
                  'Expiry date',
                  DateFormat('dd MMM yyyy').format(credit.expiryDate),
                  colorScheme,
                ),
                _buildDetailRow('Status', credit.status, colorScheme),
                if (credit.grantedBy.isNotEmpty)
                  _buildDetailRow('Granted by', credit.grantedBy, colorScheme),
                if (credit.usedAt != null)
                  _buildDetailRow(
                    'Used at',
                    DateFormat('dd MMM yyyy').format(credit.usedAt!),
                    colorScheme,
                  ),
                if (credit.leaveId != null)
                  _buildDetailRow(
                    'Linked leave ID',
                    credit.leaveId!,
                    colorScheme,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status, bool isWarning) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color;
    String label = status;

    switch (status) {
      case 'AVAILABLE':
        color = isWarning ? colorScheme.tertiary : colorScheme.primary;
        label = isWarning ? 'Expiring soon' : 'Available';
        break;
      case 'USED':
        color = colorScheme.tertiary;
        label = 'Used';
        break;
      case 'EXPIRED':
        color = colorScheme.error;
        label = 'Expired';
        break;
      default:
        color = colorScheme.outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _GrantResultDialog extends StatelessWidget {
  const _GrantResultDialog({
    required this.granted,
    required this.skipped,
    required this.onDismiss,
  });

  final int granted;
  final List<dynamic> skipped;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Grant result',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Granted: $granted',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (skipped.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Skipped (${skipped.length}):',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              ...skipped.take(15).map<Widget>((e) {
                final id = e is Map ? e['employeeId']?.toString() ?? '' : '';
                final reason = e is Map ? e['reason']?.toString() ?? '' : '';
                return Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    '$id: $reason',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                );
              }),
              if (skipped.length > 15)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '... and ${skipped.length - 15} more',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'OK',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
        FilledButton(
          onPressed: onDismiss,
          child: Text(
            'Done',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
