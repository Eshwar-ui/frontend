import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/providers/notification_settings_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSectionTitle(
                  'General',
                  Icons.settings_outlined,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                Consumer<NotificationSettingsProvider>(
                  builder: (context, settingsProvider, _) {
                    return _buildNotificationToggle(
                      context,
                      'Enable Notifications',
                      'Receive push notifications from the app',
                      settingsProvider.notificationsEnabled,
                      (value) async {
                        await settingsProvider.setNotificationsEnabled(value);
                        // Update notification provider polling
                        final notificationProvider =
                            Provider.of<NotificationProvider>(
                              context,
                              listen: false,
                            );
                        if (value) {
                          notificationProvider.startPolling(
                            interval: Duration(
                              seconds: settingsProvider.pollingInterval,
                            ),
                          );
                        } else {
                          notificationProvider.stopPolling();
                        }
                      },
                      Icons.notifications_outlined,
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  'Notification Preferences',
                  Icons.tune,
                  Colors.purple,
                ),
                const SizedBox(height: 12),
                Consumer<NotificationSettingsProvider>(
                  builder: (context, settingsProvider, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildToggleTile(
                            context,
                            'Sound',
                            'Play sound for notifications',
                            settingsProvider.soundEnabled,
                            (value) => settingsProvider.setSoundEnabled(value),
                            Icons.volume_up_outlined,
                          ),
                          Divider(
                            color: theme.dividerColor,
                            height: 1,
                            indent: 60,
                          ),
                          _buildToggleTile(
                            context,
                            'Vibration',
                            'Vibrate when notifications arrive',
                            settingsProvider.vibrationEnabled,
                            (value) =>
                                settingsProvider.setVibrationEnabled(value),
                            Icons.vibration_outlined,
                          ),
                          Divider(
                            color: theme.dividerColor,
                            height: 1,
                            indent: 60,
                          ),
                          _buildToggleTile(
                            context,
                            'Badge Count',
                            'Show unread count on app icon',
                            settingsProvider.badgeEnabled,
                            (value) => settingsProvider.setBadgeEnabled(value),
                            Icons.circle_notifications_outlined,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  'Notification Types',
                  Icons.filter_list,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                Consumer<NotificationSettingsProvider>(
                  builder: (context, settingsProvider, _) {
                    final isNotificationsEnabled =
                        settingsProvider.notificationsEnabled;
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildToggleTile(
                            context,
                            'Attendance',
                            'Notifications about attendance',
                            settingsProvider.attendanceNotifications,
                            (value) => settingsProvider
                                .setAttendanceNotifications(value),
                            Icons.access_time_outlined,
                            enabled: isNotificationsEnabled,
                          ),
                          Divider(
                            color: theme.dividerColor,
                            height: 1,
                            indent: 60,
                          ),
                          _buildToggleTile(
                            context,
                            'Leave Requests',
                            'Notifications about leave requests',
                            settingsProvider.leaveNotifications,
                            (value) =>
                                settingsProvider.setLeaveNotifications(value),
                            Icons.calendar_today_outlined,
                            enabled: isNotificationsEnabled,
                          ),
                          Divider(
                            color: theme.dividerColor,
                            height: 1,
                            indent: 60,
                          ),
                          _buildToggleTile(
                            context,
                            'Holidays',
                            'Notifications about holidays',
                            settingsProvider.holidayNotifications,
                            (value) =>
                                settingsProvider.setHolidayNotifications(value),
                            Icons.event_outlined,
                            enabled: isNotificationsEnabled,
                          ),
                          Divider(
                            color: theme.dividerColor,
                            height: 1,
                            indent: 60,
                          ),
                          _buildToggleTile(
                            context,
                            'Payslips',
                            'Notifications about payslips',
                            settingsProvider.payslipNotifications,
                            (value) =>
                                settingsProvider.setPayslipNotifications(value),
                            Icons.receipt_outlined,
                            enabled: isNotificationsEnabled,
                          ),
                          Divider(
                            color: theme.dividerColor,
                            height: 1,
                            indent: 60,
                          ),
                          _buildToggleTile(
                            context,
                            'General',
                            'General app notifications',
                            settingsProvider.generalNotifications,
                            (value) =>
                                settingsProvider.setGeneralNotifications(value),
                            Icons.info_outline,
                            enabled: isNotificationsEnabled,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  'Advanced',
                  Icons.psychology_outlined,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                Consumer<NotificationSettingsProvider>(
                  builder: (context, settingsProvider, _) {
                    return _buildPollingIntervalTile(
                      context,
                      settingsProvider.pollingInterval,
                      (value) async {
                        await settingsProvider.setPollingInterval(value);
                        // Restart polling with new interval
                        final notificationProvider =
                            Provider.of<NotificationProvider>(
                              context,
                              listen: false,
                            );
                        if (settingsProvider.notificationsEnabled) {
                          notificationProvider.stopPolling();
                          notificationProvider.startPolling(
                            interval: Duration(seconds: value),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon, {
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  color: colorScheme.onSurface.withOpacity(0.7 * opacity),
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
                        color: colorScheme.onSurface.withOpacity(opacity),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6 * opacity),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: enabled ? onChanged : null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPollingIntervalTile(
    BuildContext context,
    int currentInterval,
    ValueChanged<int> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.refresh_outlined,
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
                        'Update Frequency',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Check for new notifications every $currentInterval seconds',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildIntervalSelector(context, currentInterval, onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(
    BuildContext context,
    int currentInterval,
    ValueChanged<int> onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final intervals = [15, 30, 60, 120, 300]; // 15s, 30s, 1min, 2min, 5min

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: intervals.map((interval) {
        final isSelected = currentInterval == interval;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onChanged(interval),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  interval < 60
                      ? '${interval}s'
                      : interval < 3600
                      ? '${interval ~/ 60}m'
                      : '${interval ~/ 3600}h',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
