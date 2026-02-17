import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';
import 'package:quantum_dashboard/utils/string_extensions.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';
import 'package:quantum_dashboard/widgets/photo_upload_widget.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
            centerTitle: true,
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            expandedHeight: 300,
            floating: false,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showModalBottomSheet(
                    useSafeArea: true,
                    context: context,
                    isScrollControlled: false,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) {
                      return Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        padding: EdgeInsets.all(16),
                        child: PhotoUploadWidget(
                          employee: user,
                          size: 200,
                          onPhotoUploaded: (updatedEmployee) {
                            Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            ).setUser(updatedEmployee);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              centerTitle: true,
              expandedTitleScale: 1.2,
              title: Container(
                alignment: Alignment.center,
                // padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                width: double.infinity,
                height: 55,
                color: Colors.blue.shade700,
                child: Text(
                  maxLines: 1,
                  user.fullName.toTitleCase(),
                  style: AppTextStyles.heading.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image:
                            (() {
                                  if (user.profileImage.isNotEmpty) {
                                    if (user.profileImage.startsWith(
                                      'data:image',
                                    )) {
                                      try {
                                        final String base64String = user
                                            .profileImage
                                            .split(',')
                                            .last;
                                        final bytes = base64Decode(
                                          base64String,
                                        );
                                        return MemoryImage(bytes);
                                      } catch (_) {
                                        return const AssetImage(
                                          'assets/avatars/avatar.png',
                                        );
                                      }
                                    } else {
                                      return NetworkImage(user.profileImage);
                                    }
                                  }
                                  return const AssetImage(
                                    'assets/avatars/avatar.png',
                                  );
                                })()
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade700,
                          Colors.blue.shade700.withOpacity(0.5),
                        ],
                        stops: [0.2, 0.7],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 100),
                    child: Center(
                      child: PhotoUploadWidget(
                        employee: user,
                        size: 150,
                        onPhotoUploaded: (updatedEmployee) {
                          // Update auth provider with new user data
                          Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).setUser(updatedEmployee);
                        },
                      ),
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
                child: Column(
                  children: [
                    _buildPersonalInfoCard(user),
                    SizedBox(height: 16),
                    _buildWorkInfoCard(user),
                    SizedBox(height: 16),
                    _buildContactInfoCard(user),
                    SizedBox(height: 16),
                    _buildBankingInfoCard(user),
                    SizedBox(height: 16),
                    _buildGovernmentInfoCard(user),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // Personal Information Card
  Widget _buildPersonalInfoCard(Employee user) {
    return _buildSectionCard(
      title: 'Personal Information',
      icon: Icons.person,
      children: [
        _buildInfoRow(Icons.person, 'Full Name', user.fullName),
        _buildInfoRow(Icons.badge, 'Employee ID', user.employeeId),
        _buildInfoRow(Icons.person_outline, 'First Name', user.firstName),
        _buildInfoRow(Icons.person_outline, 'Last Name', user.lastName),
        _buildInfoRow(Icons.wc, 'Gender', user.gender ?? 'Not specified'),
        _buildInfoRow(
          Icons.cake,
          'Date of Birth',
          _formatDate(user.dateOfBirth),
        ),
        _buildInfoRow(
          Icons.family_restroom,
          'Father\'s Name',
          user.fathername ?? 'Not specified',
        ),
      ],
    );
  }

  // Work Information Card
  Widget _buildWorkInfoCard(Employee user) {
    return _buildSectionCard(
      title: 'Work Information',
      icon: Icons.work,
      children: [
        _buildInfoRow(
          Icons.business,
          'Department',
          user.department ?? 'Not specified',
        ),
        _buildInfoRow(
          Icons.assignment_ind,
          'Designation',
          user.designation ?? 'Not specified',
        ),
        _buildInfoRow(Icons.grade, 'Grade', user.grade ?? 'Not specified'),
        _buildInfoRow(
          Icons.admin_panel_settings,
          'Role',
          user.role ?? 'Not specified',
        ),
        _buildInfoRow(
          Icons.supervisor_account,
          'Reports To',
          user.report ?? 'Not specified',
        ),
        _buildInfoRow(
          Icons.calendar_today,
          'Joining Date',
          _formatDate(user.joiningDate),
        ),
      ],
    );
  }

  // Contact Information Card
  Widget _buildContactInfoCard(Employee user) {
    return _buildSectionCard(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      children: [
        _buildInfoRow(Icons.email, 'Email', user.email, copyable: true),
        _buildInfoRow(Icons.phone, 'Mobile', user.mobile, copyable: true),
        _buildInfoRow(
          Icons.location_on,
          'Address',
          user.address ?? 'Not specified',
        ),
      ],
    );
  }

  // Banking Information Card
  Widget _buildBankingInfoCard(Employee user) {
    return _buildSectionCard(
      title: 'Banking Information',
      icon: Icons.account_balance,
      children: [
        _buildInfoRow(
          Icons.account_balance,
          'Bank Name',
          user.bankname ?? 'Not specified',
        ),
        _buildInfoRow(
          Icons.credit_card,
          'Account Number',
          user.accountnumber != null
              ? _maskAccountNumber(user.accountnumber!)
              : 'Not specified',
          copyable: user.accountnumber != null,
        ),
        _buildInfoRow(
          Icons.code,
          'IFSC Code',
          user.ifsccode ?? 'Not specified',
          copyable: user.ifsccode != null,
        ),
      ],
    );
  }

  // Government Information Card
  Widget _buildGovernmentInfoCard(Employee user) {
    return _buildSectionCard(
      title: 'Government Information',
      icon: Icons.description,
      children: [
        _buildInfoRow(
          Icons.credit_card,
          'PAN Number',
          user.PANno != null ? _maskPAN(user.PANno!) : 'Not specified',
          copyable: user.PANno != null,
        ),
        _buildInfoRow(
          Icons.assignment,
          'UAN Number',
          user.UANno ?? 'Not specified',
          copyable: user.UANno != null,
        ),
        _buildInfoRow(
          Icons.local_hospital,
          'ESI Number',
          user.ESIno ?? 'Not specified',
          copyable: user.ESIno != null,
        ),
      ],
    );
  }

  // Generic section card builder
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return CustomFloatingContainer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue.shade700, size: 24),
                SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (copyable && value != 'Not specified')
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        onPressed: () =>
                            _copyToClipboard(context, value, label),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        tooltip: 'Copy $label',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return 'XXXX-XXXX-${accountNumber.substring(accountNumber.length - 4)}';
  }

  String _maskPAN(String pan) {
    if (pan.length <= 4) return pan;
    return '${pan.substring(0, 3)}XXXXXX${pan.substring(pan.length - 1)}';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
