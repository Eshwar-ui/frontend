import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/screens/profile_screen.dart';
import 'package:quantum_dashboard/services/credential_storage_service.dart';
import 'package:quantum_dashboard/utils/constants.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_button.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer2<NavigationProvider, AuthProvider>(
        builder: (context, navigationProvider, authProvider, child) {
          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  shrinkWrap: false,
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    DrawerHeader(
                      curve: Curves.easeInOutBack,
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(AppAssets.quantumLogoV),
                    ),
                    if (authProvider.isAdmin) ...[
                      // Divider(color: Colors.grey[300], thickness: 1),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          authProvider.isAdmin ? 'ADMIN PANEL' : 'HR PANEL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        context: context,
                        navigationProvider: navigationProvider,
                        page: NavigationPage.AdminEmployees,
                        icon: Icons.people,
                        title: 'Manage Employees',
                      ),
                      _buildDrawerItem(
                        context: context,
                        navigationProvider: navigationProvider,
                        page: NavigationPage.AdminLeaveRequests,
                        icon: Icons.assignment,
                        title: 'Leave Requests',
                      ),
                      _buildDrawerItem(
                        context: context,
                        navigationProvider: navigationProvider,
                        page: NavigationPage.AdminHolidays,
                        icon: Icons.calendar_today,
                        title: 'Manage Holidays',
                      ),
                      Divider(color: Colors.grey[300], thickness: 1),
                    ],
                    _buildDrawerItem(
                      context: context,
                      navigationProvider: navigationProvider,
                      page: NavigationPage.Dashboard,
                      icon: AppAssets.dashboardIcon,
                      title: 'Dashboard',
                    ),
                    _buildDrawerItem(
                      context: context,
                      navigationProvider: navigationProvider,
                      page: NavigationPage.Leaves,
                      icon: AppAssets.leavesIcon,
                      title: 'Leaves',
                    ),
                    _buildDrawerItem(
                      context: context,
                      navigationProvider: navigationProvider,
                      page: NavigationPage.Attendance,
                      icon: AppAssets.attendanceIcon,
                      title: 'Attendance',
                    ),
                    _buildDrawerItem(
                      context: context,
                      navigationProvider: navigationProvider,
                      page: NavigationPage.Payslips,
                      icon: AppAssets.payslipIcon,
                      title: 'Payslips',
                    ),
                    _buildDrawerItem(
                      context: context,
                      navigationProvider: navigationProvider,
                      page: NavigationPage.Holidays,
                      icon: AppAssets.holidaysIcon,
                      title: 'Holidays',
                    ),

                    // All Employees (read-only list, visible to all logged-in users)
                    // _buildDrawerItem(
                    //   context: context,
                    //   navigationProvider: navigationProvider,
                    //   page: NavigationPage.AllEmployees,
                    //   icon: Icons.group,
                    //   title: 'All Employees',
                    // ),

                    // Admin-only sections (includes HR)
                    _buildDrawerItem(
                      context: context,
                      navigationProvider: navigationProvider,
                      page: NavigationPage.ChangePassword,
                      icon: AppAssets.changepasswordIcon,
                      title: 'Change Password',
                    ),
                  ],
                ),
              ),
              // Profile and other buttons at the bottom
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomButton(
                  icon: Icons.person,
                  text: 'Profile',
                  onPressed: () {
                    // Handle profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: CustomButton(
                  icon: Icons.settings,
                  text: 'Settings',
                  onPressed: () {
                    _showSettingsDialog(context);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: CustomButton(
                  icon: Icons.logout,
                  text: 'Logout',
                  onPressed: () {
                    // Handle logout
                    authProvider.logout();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required NavigationProvider navigationProvider,
    required NavigationPage page,
    required dynamic icon,
    required String title,
  }) {
    final isSelected = navigationProvider.currentPage == page;
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xff0079C1),
      leading: icon is String
          ? SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              color: isSelected ? Colors.white : Colors.black,
            )
          : Icon(
              icon as IconData,
              size: 24,
              color: isSelected ? Colors.white : Colors.black,
            ),
      title: Text(
        title,
        style: AppTextStyles.button.copyWith(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
      onTap: () {
        navigationProvider.setCurrentPage(page);
        Navigator.pop(context); // Close the drawer
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saved Credentials',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>?>(
                future: CredentialStorageService.getSavedCredentials(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    final credentials = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${credentials['email']}'),
                        Text(
                          'Last login: ${_formatLastLogin(credentials['lastLogin'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await CredentialStorageService.clearCredentials();
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Saved credentials cleared'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text('Clear'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Text('No saved credentials found'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Close'),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }
}
