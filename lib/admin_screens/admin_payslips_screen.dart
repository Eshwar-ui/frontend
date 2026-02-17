import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/screens/generate_payslip_screen.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminPayslipsScreen extends StatefulWidget {
  const AdminPayslipsScreen({super.key});

  @override
  State<AdminPayslipsScreen> createState() => _AdminPayslipsScreenState();
}

class _AdminPayslipsScreenState extends State<AdminPayslipsScreen> {
  String? _selectedEmployeeId;
  int? _selectedMonth;
  int? _selectedYear;
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final FocusNode _employeeSearchFocusNode = FocusNode();

  Uri _withCacheBuster(Uri uri) {
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['v'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: qp);
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
    _employeeSearchFocusNode.addListener(_onEmployeeSearchFocusChange);
    _employeeSearchController.addListener(_onEmployeeSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
      _loadPayslips();
    });
  }

  @override
  void dispose() {
    _employeeSearchController.removeListener(_onEmployeeSearchFocusChange);
    _employeeSearchController.dispose();
    _employeeSearchFocusNode.removeListener(_onEmployeeSearchFocusChange);
    _employeeSearchFocusNode.dispose();
    super.dispose();
  }

  void _onEmployeeSearchFocusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPayslips() async {
    final payslipProvider = Provider.of<PayslipProvider>(
      context,
      listen: false,
    );
    await payslipProvider.getPayslips(
      _selectedEmployeeId ?? '',
      month: _selectedMonth,
      year: _selectedYear,
    );
  }

  Future<void> _generatePayslip() async {
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );

    if (employeeProvider.employees.isEmpty) {
      SnackbarUtils.showError(context, 'Please load employees first');
      return;
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => GeneratePayslipScreen(
          employees: employeeProvider.employees,
          employeeId: _selectedEmployeeId,
          initialMonth: _selectedMonth,
          initialYear: _selectedYear,
        ),
      ),
    );

    if (result != null) {
      final payslipProvider = Provider.of<PayslipProvider>(
        context,
        listen: false,
      );
      try {
        final generateResult = await payslipProvider.generatePayslip(
          empId: result['empId'] as String,
          month: result['month'] as int,
          year: result['year'] as int,
          basicSalary: result['basicSalary'] as double,
          hra: result['hra'] as double,
          ta: result['ta'] as double,
          da: result['da'] as double,
          conveyanceAllowance: result['conveyanceAllowance'] as double,
          total: result['total'] as double,
          employeesContributionPF: result['employeesContributionPF'] as double,
          employersContributionPF: result['employersContributionPF'] as double,
          professionalTAX: result['professionalTAX'] as double,
          totalDeductions: result['totalDeductions'] as double,
          netSalary: result['netSalary'] as double,
          paidDays: result['paidDays'] as int,
          lopDays: result['lopDays'] as int,
          arrear: result['arrear'] as double,
        );

        if (mounted) {
          if (generateResult['success'] == false ||
              generateResult['error'] != null) {
            final errorMessage =
                generateResult['error'] ??
                generateResult['message'] ??
                'Failed to generate payslip';
            SnackbarUtils.showError(context, errorMessage);
          } else {
            SnackbarUtils.showSuccess(
              context,
              'Payslip generated successfully!',
            );
            _loadPayslips();
          }

          // Notification is created automatically by backend
          // Refresh notification count if provider is available
          try {
            final notificationProvider = Provider.of<NotificationProvider>(
              context,
              listen: false,
            );
            await notificationProvider.loadUnreadCount();
          } catch (e) {
            // Notification provider might not be available, ignore
          }
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Failed to generate payslip: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _deletePayslip(Payslip payslip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payslip'),
        content: Text(
          'Are you sure you want to delete the payslip for ${payslip.empId} - ${payslip.period}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final payslipProvider = Provider.of<PayslipProvider>(
        context,
        listen: false,
      );
      try {
        await payslipProvider.deletePayslip(payslip.id);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Payslip deleted successfully!');
          _loadPayslips();
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Failed to delete payslip: ${e.toString()}',
          );
        }
      }
    }
  }

  Future<void> _viewPayslip(Payslip payslip) async {
    // Check if URL is empty or null
    if (payslip.payslipUrl.isEmpty) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Payslip URL is not available. Please regenerate the payslip.',
        );
      }
      return;
    }

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Parse URL
      final urlString = payslip.payslipUrl.trim();

      // Validate URL format
      if (!urlString.startsWith('http://') &&
          !urlString.startsWith('https://')) {
        throw Exception(
          'Invalid URL format. URL must start with http:// or https://',
        );
      }

      final url = _withCacheBuster(Uri.parse(urlString));

      // Force external app/browser for reliable PDF rendering on mobile.
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!launched && mounted) {
        SnackbarUtils.showError(
          context,
          'Could not open payslip. Please check if a browser is available.',
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        SnackbarUtils.showError(
          context,
          'Failed to open payslip: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Only administrators can access this page.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Payslips',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<NavigationProvider>(
              context,
              listen: false,
            ).setCurrentPage(NavigationPage.Dashboard);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPayslips,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _generatePayslip,
            tooltip: 'Generate Payslip',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use Column for smaller screens, Row for larger screens
                final isWide = constraints.maxWidth > 600;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildEmployeeSearch(
                          colorScheme,
                          employeeProvider,
                          isDark,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: _buildMonthDropdown(colorScheme)),
                      SizedBox(width: 12),
                      Expanded(child: _buildYearDropdown(colorScheme)),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildEmployeeSearch(
                        colorScheme,
                        employeeProvider,
                        isDark,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildMonthDropdown(colorScheme)),
                          SizedBox(width: 12),
                          Expanded(child: _buildYearDropdown(colorScheme)),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          // Content
          Expanded(
            child: Consumer<PayslipProvider>(
              builder: (context, payslipProvider, child) {
                if (payslipProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (payslipProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading payslips',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: colorScheme.error,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          payslipProvider.error!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPayslips,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final payslips = payslipProvider.payslips;

                if (payslips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No payslips found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Generate a new payslip to get started',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _generatePayslip,
                          icon: Icon(Icons.add),
                          label: Text('Generate Payslip'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 120, // Extra padding for nav bar
                  ),
                  itemCount: payslips.length,
                  itemBuilder: (context, index) {
                    final payslip = payslips[index];
                    return _buildPayslipCard(payslip, colorScheme, isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipCard(
    Payslip payslip,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewPayslip(payslip),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary, width: 1),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: colorScheme.primary,
                  size: 32,
                ),
              ),
              SizedBox(width: 12),

              // Payslip details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      payslip.empId,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            SizedBox(width: 4),
                            Text(
                              payslip.period,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Employee ID: ${payslip.empId}',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4),
              _buildActionButtons(payslip, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Payslip payslip, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(Icons.open_in_new),
          iconSize: 20,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(),
          color: colorScheme.primary,
          onPressed: () => _viewPayslip(payslip),
          tooltip: 'View Payslip',
        ),
        IconButton(
          icon: Icon(Icons.delete),
          iconSize: 20,
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(),
          color: colorScheme.error,
          onPressed: () => _deletePayslip(payslip),
          tooltip: 'Delete Payslip',
        ),
      ],
    );
  }

  List<Employee> _getFilteredEmployees(
    EmployeeProvider employeeProvider,
    String query,
  ) {
    if (query.isEmpty) return employeeProvider.employees;
    final q = query.trim().toLowerCase();
    return employeeProvider.employees.where((e) {
      return e.fullName.toLowerCase().contains(q) ||
          e.employeeId.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildEmployeeSearch(
    ColorScheme colorScheme,
    EmployeeProvider employeeProvider,
    bool isDark,
  ) {
    final query = _employeeSearchController.text.trim();
    final showList = _employeeSearchFocusNode.hasFocus;
    final filtered = _getFilteredEmployees(employeeProvider, query);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _employeeSearchController,
          focusNode: _employeeSearchFocusNode,
          onChanged: (_) => setState(() {}),
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
            suffixIcon: _selectedEmployeeId != null
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedEmployeeId = null;
                        _employeeSearchController.clear();
                      });
                      _loadPayslips();
                    },
                    tooltip: 'Clear selection',
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          onTap: () {
            if (_selectedEmployeeId != null) {
              _employeeSearchController.clear();
              setState(() => _selectedEmployeeId = null);
            }
          },
        ),
        if (showList) ...[
          SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.people,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      'All Employees',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedEmployeeId = null;
                        _employeeSearchController.clear();
                      });
                      _employeeSearchFocusNode.unfocus();
                      _loadPayslips();
                    },
                  ),
                  Divider(height: 1),
                  ...filtered.map((emp) {
                    final isSelected = _selectedEmployeeId == emp.employeeId;
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
                        final selectedLabel =
                            '${emp.employeeId} - ${emp.fullName}';
                        setState(() {
                          _selectedEmployeeId = emp.employeeId;
                          _employeeSearchController.value =
                              TextEditingValue(
                                text: selectedLabel,
                                selection: TextSelection.collapsed(
                                  offset: selectedLabel.length,
                                ),
                              );
                        });
                        _employeeSearchFocusNode.unfocus();
                        _loadPayslips();
                      },
                    );
                  }),
                  if (filtered.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No employees match "$query"',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMonthDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<int?>(
      value: _selectedMonth,
      decoration: InputDecoration(
        labelText: 'Month',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      menuMaxHeight: 300,
      isExpanded: true,
      items: [
        DropdownMenuItem<int?>(value: null, child: Text('All Months')),
        ...List.generate(12, (index) {
          final month = index + 1;
          return DropdownMenuItem<int?>(
            value: month,
            child: Text(
              DateFormat('MMMM').format(DateTime(2024, month)),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedMonth = value;
        });
        _loadPayslips();
      },
    );
  }

  Widget _buildYearDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<int?>(
      value: _selectedYear,
      decoration: InputDecoration(
        labelText: 'Year',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      menuMaxHeight: 300,
      isExpanded: true,
      items: List.generate(5, (index) {
        final year = DateTime.now().year - 2 + index;
        return DropdownMenuItem<int?>(
          value: year,
          child: Text(year.toString()),
        );
      }),
      onChanged: (value) {
        setState(() {
          _selectedYear = value;
        });
        _loadPayslips();
      },
    );
  }
}
