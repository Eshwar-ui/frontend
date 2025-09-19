// import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:quantum_dashboard/models/user_model.dart';
// // import 'package:quantum_dashboard/providers/employee_provider.dart';
// // import 'package:quantum_dashboard/utils/text_styles.dart';

// // class AllEmployeesScreen extends StatefulWidget {
// //   @override
// //   _AllEmployeesScreenState createState() => _AllEmployeesScreenState();
// // }

// // class _AllEmployeesScreenState extends State<AllEmployeesScreen> {
// //   final TextEditingController _searchController = TextEditingController();
// //   String _searchTerm = '';
// //   String? _selectedDesignation;

// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       if (!mounted) return;
// //       context.read<EmployeeProvider>().getAllEmployees();
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     _searchController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return SizedBox.shrink();
// //   }

//   // Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
//       decoration: BoxDecoration(
//         color: Color(0xFF1976D2),
//         borderRadius: BorderRadius.only(
//           bottomLeft: Radius.circular(16),
//           bottomRight: Radius.circular(16),
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.group, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text(
//                   'All Employees',
//                   style: AppTextStyles.subheading.copyWith(color: Colors.white),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//             _buildSearchBar(),
//             SizedBox(height: 10),
//             _buildDesignationFilter(),
//           ],
//         ),
//       ),
//     );
//   // }

//   // Widget _buildSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       padding: EdgeInsets.symmetric(horizontal: 12),
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           icon: Icon(Icons.search),
//           hintText: 'Search by name, id, or designation',
//           border: InputBorder.none,
//         ),
//         onChanged: (value) => setState(() => _searchTerm = value.trim()),
//       ),
//     );
//   // }

//   // Widget _buildDesignationFilter() {
//     final employeeProvider = Provider.of<EmployeeProvider>(
//       context,
//       listen: false,
//     );
//     // Build distinct designations from current list
//     final Set<String> designations = {
//       for (final e in employeeProvider.employees)
//         if ((e.designation ?? '').trim().isNotEmpty) e.designation!.trim(),
//     };
//     final List<String> items = ['All', ...designations.toList()..sort()];

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       padding: EdgeInsets.symmetric(horizontal: 12),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: _selectedDesignation ?? 'All',
//           isExpanded: true,
//           items: items
//               .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
//               .toList(),
//           onChanged: (value) async {
//             setState(
//               () => _selectedDesignation = value == 'All' ? null : value,
//             );
//             // Server-side filter via provider
//             await Provider.of<EmployeeProvider>(
//               context,
//               listen: false,
//             ).getAllEmployees(designation: _selectedDesignation);
//           },
//         ),
//       ),
//     );
//   // }

//   // List<Employee> _filter(List<Employee> employees) {
//   //   if (_searchTerm.isEmpty) return employees;
//   //   final t = _searchTerm.toLowerCase();
//   //   return employees.where((e) {
//   //     return (e.fullName.toLowerCase().contains(t)) ||
//   //         (e.employeeId.toLowerCase().contains(t)) ||
//   //         ((e.designation ?? '').toLowerCase().contains(t)) ||
//   //         ((e.department ?? '').toLowerCase().contains(t));
//   //   }).toList();
//   // }

//   // Widget _employeeTile(Employee e) {
//     return Card(
//       margin: EdgeInsets.only(bottom: 10),
//       elevation: 2,
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Color(0xFF1976D2),
//           child: Text(
//             e.firstName.isNotEmpty ? e.firstName[0].toUpperCase() : '?',
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//         title: Text(
//           e.fullName,
//           style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
//         ),
//         subtitle: Text('ID: ${e.employeeId}  •  ${e.designation ?? 'N/A'}'),
//         trailing: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               e.department ?? '—',
//               style: TextStyle(fontSize: 12, color: Colors.grey[700]),
//             ),
//             SizedBox(height: 4),
//             Text(
//               e.email,
//               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   // }
// // }
