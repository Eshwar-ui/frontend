import 'package:flutter/material.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

class PayslipsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payslips', style: AppTextStyles.heading)),
      body: Center(child: Text('Payslips Screen', style: AppTextStyles.body)),
    );
  }
}