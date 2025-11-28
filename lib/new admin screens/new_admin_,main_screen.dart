import 'package:flutter/material.dart';
import 'package:quantum_dashboard/new_Screens/new_dashboard.dart';
import 'package:quantum_dashboard/widgets/appBar.dart';
import 'package:quantum_dashboard/widgets/app_drawer.dart';

class Admin_main_screen extends StatefulWidget {
  const Admin_main_screen({super.key});

  @override
  State<Admin_main_screen> createState() => _Admin_main_screenState();
}

class _Admin_main_screenState extends State<Admin_main_screen> {
  @override
  Widget build(BuildContext context) {
    List _admin_pages =[
        
    ];

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Text('Admin Main Screen'),
            Text('Admin Main Screen'),
            Text('Admin Main Screen'),
          ],
        ),
      ),
      appBar: CustomAppBar(),

      body: Column(children: [Text('Admin Main Screen')]),
    );
  }
}
