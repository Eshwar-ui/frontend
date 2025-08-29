import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/screens/profile_screen.dart';
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
          return ListView(
            shrinkWrap: false,
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                curve: Curves.easeInOutBack,
                padding: const EdgeInsets.all(20),
                child: Image.asset(AppAssets.quantumLogoV),
              ),
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
              
              // Admin-only sections (includes HR)
              if (authProvider.isAdmin) ...[
                Divider(color: Colors.grey[300], thickness: 1),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    authProvider.isHR ? 'HR PANEL' : 'ADMIN PANEL',
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
                Divider(color: Colors.grey[300], thickness: 1),
              ],
              
              _buildDrawerItem(
                context: context,
                navigationProvider: navigationProvider,
                page: NavigationPage.ChangePassword,
                icon: AppAssets.changepasswordIcon,
                title: 'Change Password',
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
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
}
