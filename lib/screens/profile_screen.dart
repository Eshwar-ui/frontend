import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';
import 'package:quantum_dashboard/widgets/photo_upload_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(child: Text('No user data found.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            foregroundColor: Colors.white,
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                user.fullName,
                style: AppTextStyles.heading.copyWith(color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image.asset(
                  //   'assets/illustrations/profile_background.jpg', // Add a background image
                  //   fit: BoxFit.cover,
                  // ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: PhotoUploadWidget(
                      employee: user,
                      size: 100,
                      onPhotoUploaded: (updatedEmployee) {
                        // Update auth provider with new user data
                        Provider.of<AuthProvider>(context, listen: false).setUser(updatedEmployee);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildProfileInfoCard(user),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(Employee user) {
    return CustomFloatingContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.person, 'Full Name', user.fullName),
            _buildInfoRow(Icons.email, 'Email', user.email),
            _buildInfoRow(Icons.work, 'Department', user.department),
            _buildInfoRow(
              Icons.assignment_ind,
              'Designation',
              user.designation,
            ),
            _buildInfoRow(Icons.phone, 'Phone', user.phone),
            _buildInfoRow(Icons.location_on, 'Address', user.address),
            _buildInfoRow(
              Icons.calendar_today,
              'Join Date',
              user.joinDate.toLocal().toString().split(' ')[0],
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Salary',
              user.salary.toStringAsFixed(2),
            ),
            _buildInfoRow(
              Icons.check_circle,
              'Status',
              user.isActive ? 'Active' : 'Inactive',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(value, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
