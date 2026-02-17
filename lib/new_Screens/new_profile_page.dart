import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/theme_provider.dart';
import 'package:quantum_dashboard/widgets/photo_upload_widget.dart';
import 'package:quantum_dashboard/new_Screens/settings_page.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';

class NewProfilePage extends StatefulWidget {
  const NewProfilePage({super.key});

  @override
  State<NewProfilePage> createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<NewProfilePage> {
  ThemeData? _theme;
  ScaffoldMessengerState? _scaffoldMessenger;
  NavigatorState? _navigator;
  AuthProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    _navigator = Navigator.of(context);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final navigationProvider = Provider.of<NavigationProvider>(
      context,
      listen: false,
    );

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No user data found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              // _buildQuickStats(user),
              // const SizedBox(height: 24),
              if (!authProvider.isAdmin) ...[
                _buildPersonalInfoSection(user),
                const SizedBox(height: 16),
                _buildWorkInfoSection(user),
                const SizedBox(height: 16),
                _buildContactInfoSection(user),
                const SizedBox(height: 16),
                _buildBankingInfoSection(user),
                const SizedBox(height: 16),
                _buildDocumentsSection(user),
              ],
              if (authProvider.isAdmin) ...[
                const SizedBox(height: 16),
                _buildAdminSettingsSection(navigationProvider),
              ],
              const SizedBox(height: 16),
              _buildSettingsButton(),
              const SizedBox(height: 24),
              _buildLogoutButton(user),
              const SizedBox(height: 120), // Extra padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Employee user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            // Profile Image
            GestureDetector(
              onTap: () => _showPhotoUploadModal(user),
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(child: _buildProfileImage(user)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              user.fullName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Employee ID
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.badge, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    user.employeeId,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Designation & Department
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.designation != null) ...[
                  _buildHeaderChip(user.designation!, Icons.work_outline),
                  SizedBox(width: 12),
                ],
                if (user.department != null)
                  _buildHeaderChip(user.department!, Icons.business),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(Employee user) {
    if (user.profileImage.isNotEmpty) {
      if (user.profileImage.startsWith('data:image')) {
        try {
          final String base64String = user.profileImage.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {
          return _buildPlaceholderAvatar(user.firstName);
        }
      } else {
        try {
          final uri = Uri.tryParse(user.profileImage);
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
            return Image.network(
              user.profileImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderAvatar(user.firstName);
              },
            );
          }
        } catch (_) {}
        return _buildPlaceholderAvatar(user.firstName);
      }
    }
    return _buildPlaceholderAvatar(user.firstName);
  }

  Widget _buildPlaceholderAvatar(String firstName) {
    return Container(
      color: Color(0xFF1976D2),
      child: Center(
        child: Text(
          firstName.substring(0, 1).toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showPhotoUploadModal(Employee user) {
    if (!mounted || _theme == null) return;
    final theme = _theme!;
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Update Profile Photo',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 20),
              PhotoUploadWidget(
                employee: user,
                size: 200,
                onPhotoUploaded: (updatedEmployee) {
                  if (!mounted || _authProvider == null) return;

                  // Evict the old image from the cache before updating the state.
                  // This is crucial for data URLs that don't change their "URL" but change content.
                  if (user.profileImage.isNotEmpty &&
                      user.profileImage.startsWith('data:image')) {
                    MemoryImage(
                      base64Decode(user.profileImage.split(',').last),
                    ).evict();
                  }

                  _authProvider?.setUser(updatedEmployee);
                  Navigator.of(ctx).pop();
                  _scaffoldMessenger!.showSnackBar(
                    SnackBar(
                      content: Text('Profile photo updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildQuickStats(Employee user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Department',
              user.department ?? 'N/A',
              Icons.business,
              Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Designation',
              user.designation ?? 'N/A',
              Icons.stars,
              Colors.orange,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Joined',
              DateFormat('MMM yyyy').format(user.joiningDate),
              Icons.calendar_today,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(Employee user) {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      color: Color(0xFF1976D2),
      children: [
        _buildInfoTile(Icons.person, 'Full Name', user.fullName),
        _buildInfoTile(Icons.person_outline, 'First Name', user.firstName),
        _buildInfoTile(Icons.person_outline, 'Last Name', user.lastName),
        _buildInfoTile(
          Icons.cake,
          'Date of Birth',
          DateFormat('dd MMMM yyyy').format(user.dateOfBirth),
        ),
        _buildInfoTile(Icons.wc, 'Gender', user.gender ?? 'Not specified'),
        if (user.fathername != null)
          _buildInfoTile(
            Icons.family_restroom,
            "Father's Name",
            user.fathername!,
          ),
      ],
    );
  }

  Widget _buildWorkInfoSection(Employee user) {
    return _buildSection(
      title: 'Work Information',
      icon: Icons.work_outline,
      color: Colors.purple,
      children: [
        _buildInfoTile(Icons.badge, 'Employee ID', user.employeeId),
        if (user.department != null)
          _buildInfoTile(Icons.business, 'Department', user.department!),
        if (user.designation != null)
          _buildInfoTile(Icons.stars, 'Designation', user.designation!),
        if (user.grade != null)
          _buildInfoTile(Icons.grade, 'Grade', user.grade!),
        if (user.role != null)
          _buildInfoTile(Icons.admin_panel_settings, 'Role', user.role!),
        _buildInfoTile(
          Icons.calendar_today,
          'Joining Date',
          DateFormat('dd MMMM yyyy').format(user.joiningDate),
        ),
        if (user.report != null)
          _buildInfoTile(Icons.supervisor_account, 'Reports To', user.report!),
      ],
    );
  }

  Widget _buildContactInfoSection(Employee user) {
    return _buildSection(
      title: 'Contact Information',
      icon: Icons.contact_phone,
      color: Colors.teal,
      children: [
        _buildInfoTile(Icons.email, 'Email', user.email, copyable: true),
        _buildInfoTile(Icons.phone, 'Mobile', user.mobile, copyable: true),
        if (user.address != null)
          _buildInfoTile(Icons.location_on, 'Address', user.address!),
      ],
    );
  }

  Widget _buildBankingInfoSection(Employee user) {
    return _buildSection(
      title: 'Banking Information',
      icon: Icons.account_balance,
      color: Colors.green,
      children: [
        if (user.bankname != null)
          _buildInfoTile(Icons.account_balance, 'Bank Name', user.bankname!),
        if (user.accountnumber != null)
          _buildInfoTile(
            Icons.credit_card,
            'Account Number',
            _maskAccountNumber(user.accountnumber!),
            copyable: true,
            fullValue: user.accountnumber,
          ),
        if (user.ifsccode != null)
          _buildInfoTile(
            Icons.code,
            'IFSC Code',
            user.ifsccode!,
            copyable: true,
          ),
      ],
    );
  }

  Widget _buildDocumentsSection(Employee user) {
    return _buildSection(
      title: 'Government Documents',
      icon: Icons.description,
      color: Colors.orange,
      children: [
        if (user.PANno != null)
          _buildInfoTile(
            Icons.credit_card,
            'PAN Number',
            _maskPAN(user.PANno!),
            copyable: true,
            fullValue: user.PANno,
          ),
        if (user.UANno != null)
          _buildInfoTile(
            Icons.assignment,
            'UAN Number',
            user.UANno!,
            copyable: true,
          ),
        if (user.ESIno != null)
          _buildInfoTile(
            Icons.local_hospital,
            'ESI Number',
            user.ESIno!,
            copyable: true,
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            leading: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            iconColor: color,
            collapsedIconColor: color.withOpacity(0.7),
            backgroundColor: color.withOpacity(0.05),
            collapsedBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
    String? fullValue,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colorScheme.onSurface.withOpacity(0.7),
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () => _copyToClipboard(fullValue ?? value, label),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.copy,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminSettingsSection(NavigationProvider navigationProvider) {
    return _buildSection(
      title: 'Admin Settings',
      icon: Icons.admin_panel_settings,
      color: Colors.indigo,
      children: [
        _buildAdminSettingsTile(
          Icons.business_center_rounded,
          'Manage Departments',
          'Configure organizational structure',
          () => navigationProvider.setCurrentPage(
            NavigationPage.AdminDepartments,
          ),
        ),
        _buildAdminSettingsTile(
          Icons.event_note_rounded,
          'Manage Leave Types',
          'Set up and edit leave policies',
          () =>
              navigationProvider.setCurrentPage(NavigationPage.AdminLeaveTypes),
        ),
      ],
    );
  }

  Widget _buildAdminSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurface.withOpacity(0.7),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return 'XXXX-XXXX-${accountNumber.substring(accountNumber.length - 4)}';
  }

  String _maskPAN(String pan) {
    if (pan.length <= 4) return pan;
    return '${pan.substring(0, 3)}XXXXXX${pan.substring(pan.length - 1)}';
  }

  void _copyToClipboard(String text, String label) {
    if (!mounted || _scaffoldMessenger == null) return;
    Clipboard.setData(ClipboardData(text: text));
    _scaffoldMessenger!.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('$label copied to clipboard'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSettingsButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final settingsColor = Colors.indigo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: settingsColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: settingsColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'App preferences and settings',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurface.withOpacity(0.7),
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildThemeToggleTile() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        themeProvider.toggleTheme();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: colorScheme.onSurface.withOpacity(0.7),
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    isDark ? 'Dark mode' : 'Light mode',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(Employee user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _showLogoutDialog(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showSettingsDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(message, style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ignore: unused_element
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1976D2)),
              SizedBox(width: 12),
              Text(
                'About',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quantum Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Version 2.0.0',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              Text(
                'Employee Management System',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(Employee user) {
    if (!mounted || _theme == null) return;
    final theme = _theme!;
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!mounted || _authProvider == null || _navigator == null)
                  return;
                await _authProvider!.logout();
                // Navigation will be handled by the main app based on auth state
                if (mounted) {
                  _navigator!.pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
