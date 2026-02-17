import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/models/payslip_model.dart';
import 'package:quantum_dashboard/utils/Pdf_helper.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class NewPayslipScreen extends StatefulWidget {
  @override
  _NewPayslipScreenState createState() => _NewPayslipScreenState();
}

class _NewPayslipScreenState extends State<NewPayslipScreen> {
  int _selectedYear = DateTime.now().year;

  // Store references to providers to avoid deactivated widget errors
  AuthProvider? _authProvider;
  PayslipProvider? _payslipProvider;
  bool _hasLoadedInitialData = false;

  String _withCacheBuster(String rawUrl) {
    final uri = Uri.parse(rawUrl);
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['v'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: qp).toString();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save references to providers to avoid deactivated widget errors
    try {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _payslipProvider = Provider.of<PayslipProvider>(context, listen: false);

      // Load payslips after providers are set (only once on initial setup)
      if (!_hasLoadedInitialData &&
          _authProvider != null &&
          _payslipProvider != null) {
        _hasLoadedInitialData = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadPayslips();
          }
        });
      }
    } catch (e) {
      // Handle case where context is no longer valid
      print('Error accessing providers in didChangeDependencies: $e');
    }
  }

  void _loadPayslips() {
    if (!mounted || _authProvider == null || _payslipProvider == null) {
      return;
    }

    final user = _authProvider!.user;

    if (user != null) {
      _payslipProvider!.getPayslips(user.employeeId);
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Payslips'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Year selector
            Consumer<PayslipProvider>(
              builder: (context, payslipProvider, child) {
                final localTheme = Theme.of(context);
                final localColorScheme = localTheme.colorScheme;
                final localIsDark = localTheme.brightness == Brightness.dark;

                final availableYears =
                    payslipProvider.payslips.map((p) => p.year).toSet().toList()
                      ..sort();

                // Auto-select first available year if current selection is not available
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (availableYears.isNotEmpty &&
                      !availableYears.contains(_selectedYear)) {
                    setState(() {
                      _selectedYear = availableYears.first;
                    });
                  }
                });

                return Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: localTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          localIsDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: localColorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: availableYears.contains(_selectedYear)
                              ? _selectedYear
                              : (availableYears.isNotEmpty
                                    ? availableYears.first
                                    : _selectedYear),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            hintText: 'Select Year',
                          ),
                          items: availableYears.map((year) {
                            return DropdownMenuItem(
                              value: year,
                              child: Text(
                                year.toString(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: localColorScheme.onSurface,
                                ),
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
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
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

                  return _buildGeneratedPayslipsList(payslipProvider.payslips);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratedPayslipsList(List<Payslip> payslips) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Filter payslips by selected year only
    final filteredPayslips = payslips.where((payslip) {
      return payslip.year == _selectedYear;
    }).toList();

    // Sort by month (most recent first)
    filteredPayslips.sort((a, b) => b.month.compareTo(a.month));

    if (filteredPayslips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No payslips found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              payslips.isEmpty
                  ? 'No payslips available yet'
                  : 'No payslips found for $_selectedYear',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (payslips.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(
                    isDark ? 0.3 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Available: ${payslips.map((p) => '${p.monthName} ${p.year}').join(', ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: colorScheme.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'Payslips for $_selectedYear',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(
                      isDark ? 0.3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredPayslips.length} ${filteredPayslips.length == 1 ? 'payslip' : 'payslips'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.primaryContainer.withOpacity(0.2),
                  colorScheme.primaryContainer.withOpacity(0.3),
                ]
              : [
                  colorScheme.primaryContainer.withOpacity(0.3),
                  colorScheme.primaryContainer.withOpacity(0.5),
                  colorScheme.primaryContainer.withOpacity(0.3),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (!mounted) return;
            try {
              await url_launcher.launchUrl(
                Uri.parse(_withCacheBuster(payslip.payslipUrl)),
                mode: url_launcher.LaunchMode.externalApplication,
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to open PDF: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(
                              isDark ? 0.3 : 0.2,
                            ),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        size: 28,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            payslip.monthName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${payslip.year}',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!mounted) return;
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
                        icon: Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          'Download',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: colorScheme.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!mounted) return;
                          try {
                            await url_launcher.launchUrl(
                              Uri.parse(_withCacheBuster(payslip.payslipUrl)),
                              mode: url_launcher.LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to open PDF: $e'),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.visibility_rounded, size: 18),
                        label: Text(
                          'View',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
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
        ),
      ),
    );
  }
}
