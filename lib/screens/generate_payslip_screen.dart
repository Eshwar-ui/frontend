import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/user_model.dart';

class GeneratePayslipScreen extends StatefulWidget {
  final List<Employee> employees;
  final String? employeeId;
  final int? initialMonth;
  final int? initialYear;

  const GeneratePayslipScreen({
    Key? key,
    required this.employees,
    this.employeeId,
    this.initialMonth,
    this.initialYear,
  }) : super(key: key);

  @override
  State<GeneratePayslipScreen> createState() => _GeneratePayslipScreenState();
}

class _GeneratePayslipScreenState extends State<GeneratePayslipScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedEmployeeId;
  int? _selectedMonth;
  int? _selectedYear;

  final _basicSalaryController = TextEditingController();
  final _hraController = TextEditingController();
  final _taController = TextEditingController();
  final _daController = TextEditingController();
  final _conveyanceAllowanceController = TextEditingController();

  final _employeesContributionPFController = TextEditingController();
  final _employersContributionPFController = TextEditingController();
  final _professionalTAXController = TextEditingController();

  final _paidDaysController = TextEditingController();
  final _lopDaysController = TextEditingController();
  final _arrearController = TextEditingController();

  bool _isCalculating = false;
  double _totalEarnings = 0.0;
  double _totalDeductions = 0.0;
  double _netSalary = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedEmployeeId = widget.employeeId;
    _selectedMonth = widget.initialMonth ?? DateTime.now().month;
    _selectedYear = widget.initialYear ?? DateTime.now().year;

    _paidDaysController.text = '30';
    _lopDaysController.text = '0';
    _arrearController.text = '0';

    _basicSalaryController.addListener(_calculateTotals);
    _hraController.addListener(_calculateTotals);
    _taController.addListener(_calculateTotals);
    _daController.addListener(_calculateTotals);
    _conveyanceAllowanceController.addListener(_calculateTotals);
    _employeesContributionPFController.addListener(_calculateTotals);
    _employersContributionPFController.addListener(_calculateTotals);
    _professionalTAXController.addListener(_calculateTotals);
  }

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _hraController.dispose();
    _taController.dispose();
    _daController.dispose();
    _conveyanceAllowanceController.dispose();
    _employeesContributionPFController.dispose();
    _employersContributionPFController.dispose();
    _professionalTAXController.dispose();
    _paidDaysController.dispose();
    _lopDaysController.dispose();
    _arrearController.dispose();
    super.dispose();
  }

  void _calculateTotals() {
    setState(() {
      _totalEarnings =
          _getDoubleValue(_basicSalaryController.text) +
          _getDoubleValue(_hraController.text) +
          _getDoubleValue(_taController.text) +
          _getDoubleValue(_daController.text) +
          _getDoubleValue(_conveyanceAllowanceController.text);

      _totalDeductions =
          _getDoubleValue(_employeesContributionPFController.text) +
          _getDoubleValue(_employersContributionPFController.text) +
          _getDoubleValue(_professionalTAXController.text);

      _netSalary = _totalEarnings - _totalDeductions;
    });
  }

  double _getDoubleValue(String value) {
    if (value.isEmpty) return 0.0;
    return double.tryParse(value) ?? 0.0;
  }

  Map<String, dynamic> _getFormData() {
    return {
      'empId': _selectedEmployeeId ?? '',
      'month': _selectedMonth ?? DateTime.now().month,
      'year': _selectedYear ?? DateTime.now().year,
      'basicSalary': _getDoubleValue(_basicSalaryController.text),
      'hra': _getDoubleValue(_hraController.text),
      'ta': _getDoubleValue(_taController.text),
      'da': _getDoubleValue(_daController.text),
      'conveyanceAllowance': _getDoubleValue(
        _conveyanceAllowanceController.text,
      ),
      'total': _totalEarnings,
      'employeesContributionPF': _getDoubleValue(
        _employeesContributionPFController.text,
      ),
      'employersContributionPF': _getDoubleValue(
        _employersContributionPFController.text,
      ),
      'professionalTAX': _getDoubleValue(_professionalTAXController.text),
      'totalDeductions': _totalDeductions,
      'netSalary': _netSalary,
      'paidDays': int.tryParse(_paidDaysController.text) ?? 30,
      'lopDays': int.tryParse(_lopDaysController.text) ?? 0,
      'arrear': _getDoubleValue(_arrearController.text),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Generate Payslip'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String?>(
                      value: _selectedEmployeeId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Employee ID *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: widget.employees.map((emp) {
                        return DropdownMenuItem<String?>(
                          value: emp.employeeId,
                          child: Text(
                            '${emp.employeeId} - ${emp.fullName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployeeId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an employee';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedMonth,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Month *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_month),
                            ),
                            items: List.generate(12, (index) {
                              final month = index + 1;
                              return DropdownMenuItem(
                                value: month,
                                child: Text(
                                  DateFormat(
                                    'MMMM',
                                  ).format(DateTime(2024, month)),
                                ),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedMonth = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a month';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedYear,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Year *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            items: List.generate(5, (index) {
                              final year = DateTime.now().year - 2 + index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (value) {
                              setState(() {
                                _selectedYear = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a year';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Earnings',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _basicSalaryController,
                      label: 'Basic Salary *',
                      icon: Icons.account_balance_wallet,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter basic salary';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _hraController,
                      label: 'HRA (House Rent Allowance)',
                      icon: Icons.home,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _taController,
                      label: 'TA (Travel Allowance)',
                      icon: Icons.directions_car,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _daController,
                      label: 'DA (Dearness Allowance)',
                      icon: Icons.attach_money,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _conveyanceAllowanceController,
                      label: 'Conveyance Allowance',
                      icon: Icons.train,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Deductions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _employeesContributionPFController,
                      label: 'Employee\'s Contribution PF',
                      icon: Icons.account_balance,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _employersContributionPFController,
                      label: 'Employer\'s Contribution PF',
                      icon: Icons.business,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _professionalTAXController,
                      label: 'Professional Tax',
                      icon: Icons.receipt,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Other Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _paidDaysController,
                            label: 'Paid Days *',
                            icon: Icons.event_available,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _lopDaysController,
                            label: 'LOP Days',
                            icon: Icons.event_busy,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: _arrearController,
                      label: 'Arrear',
                      icon: Icons.payment,
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Total Earnings',
                            _totalEarnings,
                            colorScheme.primary,
                          ),
                          SizedBox(height: 8),
                          _buildSummaryRow(
                            'Total Deductions',
                            _totalDeductions,
                            colorScheme.error,
                          ),
                          Divider(height: 24),
                          _buildSummaryRow(
                            'Net Salary',
                            _netSalary,
                            colorScheme.tertiary,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isCalculating
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.of(context).pop(_getFormData());
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isCalculating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text('Generate Payslip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    Color color, {
    bool isBold = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
