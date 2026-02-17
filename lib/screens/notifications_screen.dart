import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/models/notification_model.dart' as models;
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/widgets/notification_card.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter =
      'all'; // 'all', 'leave', 'payslip', 'general', 'system'
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      provider.loadNotifications();
    });
  }

  List<models.Notification> _getFilteredNotifications(
    List<models.Notification> notifications,
  ) {
    var filtered = notifications;

    // Filter by type
    if (_selectedFilter != 'all') {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }

    // Filter by read status
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    return filtered;
  }

  Map<String, List<models.Notification>> _groupByDate(
    List<models.Notification> notifications,
  ) {
    final Map<String, List<models.Notification>> grouped = {};

    for (final notification in notifications) {
      final dateKey = _getDateKey(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }

    // Sort each group by time (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () async {
                    try {
                      await provider.markAllAsRead();
                      SnackbarUtils.showSuccess(
                        context,
                        'All notifications marked as read',
                      );
                    } catch (e) {
                      SnackbarUtils.showError(
                        context,
                        'Failed to mark all as read: ${e.toString()}',
                      );
                    }
                  },
                  icon: Icon(Icons.done_all, size: 18),
                  label: Text('Mark all read'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onPrimary,
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                // Type filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All', context),
                      SizedBox(width: 8),
                      _buildFilterChip('leave', 'Leave', context),
                      SizedBox(width: 8),
                      _buildFilterChip('payslip', 'Payslip', context),
                      SizedBox(width: 8),
                      _buildFilterChip('general', 'General', context),
                      SizedBox(width: 8),
                      _buildFilterChip('system', 'System', context),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // Unread only toggle
                Row(
                  children: [
                    Checkbox(
                      value: _showUnreadOnly,
                      onChanged: (value) {
                        setState(() => _showUnreadOnly = value ?? false);
                      },
                    ),
                    Text(
                      'Show unread only',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.notifications.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.notifications.isEmpty) {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: cs.error,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: cs.error,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          provider.error!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadNotifications(),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _getFilteredNotifications(
                  provider.notifications,
                );
                final grouped = _groupByDate(filtered);

                if (filtered.isEmpty) {
                  final theme = Theme.of(context);
                  final cs = theme.colorScheme;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.85),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _showUnreadOnly
                              ? 'No unread notifications'
                              : 'You\'re all caught up!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadNotifications();
                    await provider.loadUnreadCount();
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final notifications = grouped[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateKey,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          ...notifications.map((notification) {
                            return NotificationCard(
                              notification: notification,
                              onTap: () async {
                                if (!notification.isRead) {
                                  try {
                                    await provider.markAsRead(notification.id);
                                  } catch (e) {
                                    SnackbarUtils.showError(
                                      context,
                                      'Failed to mark as read: ${e.toString()}',
                                    );
                                  }
                                }
                              },
                              onMarkAsRead: () async {
                                try {
                                  await provider.markAsRead(notification.id);
                                  SnackbarUtils.showSuccess(
                                    context,
                                    'Marked as read',
                                  );
                                } catch (e) {
                                  SnackbarUtils.showError(
                                    context,
                                    'Failed to mark as read: ${e.toString()}',
                                  );
                                }
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Notification'),
                                    content: Text(
                                      'Are you sure you want to delete this notification?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onError,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  try {
                                    await provider.deleteNotification(
                                      notification.id,
                                    );
                                    SnackbarUtils.showSuccess(
                                      context,
                                      'Notification deleted',
                                    );
                                  } catch (e) {
                                    SnackbarUtils.showError(
                                      context,
                                      'Failed to delete: ${e.toString()}',
                                    );
                                  }
                                }
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, BuildContext context) {
    final isSelected = _selectedFilter == value;
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: GoogleFonts.poppins(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
    );
  }
}
