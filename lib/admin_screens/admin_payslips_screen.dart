import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/widgets/generate_payslip_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
      _loadPayslips();
    });
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => GeneratePayslipDialog(
        employees: employeeProvider.employees,
        employeeId: _selectedEmployeeId,
        initialMonth: _selectedMonth,
        initialYear: _selectedYear,
      ),
    );

    if (result != null) {
      final payslipProvider = Provider.of<PayslipProvider>(
        context,
        listen: false,
      );
      try {
        await payslipProvider.generatePayslip(
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
          SnackbarUtils.showSuccess(context, 'Payslip generated successfully!');
          _loadPayslips();
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

      final url = Uri.parse(urlString);

      // Launch URL - use platformDefault which works best on most platforms
      final launched = await launchUrl(url, mode: LaunchMode.platformDefault);

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
                    children: [
                      Expanded(
                        child: _buildEmployeeDropdown(
                          colorScheme,
                          employeeProvider,
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
                    children: [
                      _buildEmployeeDropdown(colorScheme, employeeProvider),
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

  Widget _buildEmployeeDropdown(
    ColorScheme colorScheme,
    EmployeeProvider employeeProvider,
  ) {
    return DropdownButtonFormField<String?>(
      value: _selectedEmployeeId,
      decoration: InputDecoration(
        labelText: 'Employee',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      menuMaxHeight: 300,
      isExpanded: true,
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('All Employees', overflow: TextOverflow.ellipsis),
        ),
        ...employeeProvider.employees.map((emp) {
          return DropdownMenuItem<String?>(
            value: emp.employeeId,
            child: Text(
              '${emp.employeeId} - ${emp.fullName}',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedEmployeeId = value;
        });
        _loadPayslips();
      },
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
