import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/utils/Pdf_helper.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class PayslipsScreen extends StatefulWidget {
  @override
  _PayslipsScreenState createState() => _PayslipsScreenState();
}

class _PayslipsScreenState extends State<PayslipsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _showGeneratedPayslips = true;

  String _withCacheBuster(String rawUrl) {
    final uri = Uri.parse(rawUrl);
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['v'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: qp).toString();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPayslips();
    });
    // _loadPayslips();
  }

  void _loadPayslips() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final payslipProvider = Provider.of<PayslipProvider>(
      context,
      listen: false,
    );
    final user = authProvider.user;

    if (user != null) {
      if (_showGeneratedPayslips) {
        payslipProvider.getPayslips(user.employeeId);
      } else {
        payslipProvider.getEmployeePayslips(user.employeeId);
      }
    }
  }

  String _generatePayslipFileName(String empId, int month, int year) {
    final monthNames = [
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
    final monthName = monthNames[month - 1];
    return 'Payslip_${empId}_${monthName}_$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Payslips', style: AppTextStyles.heading),
      //   actions: [
      //     IconButton(
      //       icon: Icon(Icons.refresh),
      //       onPressed: _loadPayslips,
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          // Toggle between generated and employee payslips
          // Container(
          //   padding: EdgeInsets.all(16),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: ElevatedButton(
          //           onPressed: () {
          //             setState(() {
          //               _showGeneratedPayslips = true;
          //             });
          //             _loadPayslips();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: _showGeneratedPayslips
          //                 ? Colors.blue
          //                 : Colors.grey,
          //           ),
          //           child: Text('Generated Payslips'),
          //         ),
          //       ),
          //       SizedBox(width: 16),
          //       Expanded(
          //         child: ElevatedButton(
          //           onPressed: () {
          //             setState(() {
          //               _showGeneratedPayslips = false;
          //             });
          //             _loadPayslips();
          //           },
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: !_showGeneratedPayslips
          //                 ? Colors.blue
          //                 : Colors.grey,
          //           ),
          //           child: Text('My Uploads'),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // Month/Year selector for generated payslips
          if (_showGeneratedPayslips)
            Consumer<PayslipProvider>(
              builder: (context, payslipProvider, child) {
                final availableMonths =
                    payslipProvider.payslips
                        .map((p) => p.month)
                        .toSet()
                        .toList()
                      ..sort();
                final availableYears =
                    payslipProvider.payslips.map((p) => p.year).toSet().toList()
                      ..sort();

                // Auto-select first available month/year if current selection is not available
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (availableMonths.isNotEmpty &&
                      !availableMonths.contains(_selectedMonth)) {
                    setState(() {
                      _selectedMonth = availableMonths.first;
                    });
                  }
                  if (availableYears.isNotEmpty &&
                      !availableYears.contains(_selectedYear)) {
                    setState(() {
                      _selectedYear = availableYears.first;
                    });
                  }
                });

                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: availableMonths.contains(_selectedMonth)
                              ? _selectedMonth
                              : (availableMonths.isNotEmpty
                                    ? availableMonths.first
                                    : _selectedMonth),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                          dropdownColor: colorScheme.surfaceContainerHighest,
                          items: availableMonths.map((month) {
                            return DropdownMenuItem(
                              value: month,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  DateFormat(
                                    'MMMM',
                                  ).format(DateTime(2023, month)),
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMonth = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: availableYears.contains(_selectedYear)
                              ? _selectedYear
                              : (availableYears.isNotEmpty
                                    ? availableYears.first
                                    : _selectedYear),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                          dropdownColor: colorScheme.surfaceContainerHighest,
                          items: availableYears.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(
                                year.toString(),
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedYear = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Payslips list
          Expanded(
            child: Consumer2<AuthProvider, PayslipProvider>(
              builder: (context, authProvider, payslipProvider, child) {
                final user = authProvider.user;
                if (user == null) {
                  return Center(child: Text('No user data found.'));
                }

                if (payslipProvider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                if (payslipProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${payslipProvider.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPayslips,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (_showGeneratedPayslips) {
                  return _buildGeneratedPayslipsList(payslipProvider.payslips);
                } else {
                  return _buildEmployeePayslipsList(
                    payslipProvider.employeePayslips,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPayslipsList(List<Payslip> payslips) {
    // Filter payslips by selected month and year
    final filteredPayslips = payslips.where((payslip) {
      final matchesMonth = payslip.month == _selectedMonth;
      final matchesYear = payslip.year == _selectedYear;
      return matchesMonth && matchesYear;
    }).toList();

    if (filteredPayslips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No generated payslips found for selected period.'),
            SizedBox(height: 8),
            Text(
              'Available months: ${payslips.map((p) => '${p.monthName} ${p.year}').join(', ')}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Payslips for ${_selectedYear}',
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPayslips.length,
              itemBuilder: (context, index) {
                final payslip = filteredPayslips[index];
                return _buildMonthButton(payslip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthButton(Payslip payslip) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 32, color: Colors.blue.shade700),
            SizedBox(height: 8),
            Text(
              payslip.monthName,
              style: AppTextStyles.heading.copyWith(
                fontSize: 16,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              '${payslip.year}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            // SizedBox(height: 12),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final fileName = _generatePayslipFileName(
                        payslip.empId,
                        payslip.month,
                        payslip.year,
                      );
                      await downloadAndOpenPdf(
                        _withCacheBuster(payslip.payslipUrl),
                        fileName,
                        context,
                      );
                    },
                    icon: Icon(Icons.download, size: 18),
                    label: Text(
                      'Download ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size(double.maxFinite, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await url_launcher.launchUrl(
                          Uri.parse(_withCacheBuster(payslip.payslipUrl)),
                          mode: url_launcher.LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to open PDF: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.open_in_new, size: 18),
                    label: Text(
                      'View ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size(double.maxFinite, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeePayslipsList(List<EmployeePayslip> payslips) {
    if (payslips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No uploaded payslips found.'),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Uploaded Payslips',
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: payslips.length,
              itemBuilder: (context, index) {
                final payslip = payslips[index];
                return _buildEmployeeMonthButton(payslip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeMonthButton(EmployeePayslip payslip) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          try {
            // await PdfUtils.openPdfInExternalApp(payslip.url);
            await url_launcher.launchUrl(
              Uri.parse(_withCacheBuster(payslip.url)),
              mode: url_launcher.LaunchMode.externalApplication,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to open PDF: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.upload, size: 32, color: Colors.green.shade700),
              SizedBox(height: 8),
              Text(
                payslip.monthName,
                style: AppTextStyles.heading.copyWith(
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                '${payslip.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // await PdfUtils.openPdfInExternalApp(payslip.url);
                    await url_launcher.launchUrl(
                      Uri.parse(_withCacheBuster(payslip.url)),
                      mode: url_launcher.LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to open PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.open_in_new, size: 18),
                label: Text(
                  'Open Payslip',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
