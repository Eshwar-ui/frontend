import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/leave_model.dart';

class LeaveAccordion extends StatelessWidget {
  final Leave leave;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LeaveAccordion({
    Key? key,
    required this.leave,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: _buildTileTitle(colorScheme),
        subtitle: _buildTileSubtitle(colorScheme),
        trailing: _buildStatusChip(colorScheme),
        children: [_buildExpandedContent(context, colorScheme, isDark)],
      ),
    );
  }

  Widget _buildTileTitle(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(leave.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getLeaveTypeIcon(leave.type),
            color: _getStatusColor(leave.status),
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            leave.type,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileSubtitle(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 44),
      child: Text(
        '${DateFormat.yMMMd().format(leave.fromDate)} - ${DateFormat.yMMMd().format(leave.toDate)}',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme) {
    final statusColor = _getStatusColor(leave.status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        leave.status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Duration',
            '${leave.totalDays} day${leave.totalDays != 1 ? 's' : ''}',
            Icons.schedule_outlined,
            colorScheme,
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            'Reason',
            leave.reason,
            Icons.comment_outlined,
            colorScheme,
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            'Applied Date',
            DateFormat.yMMMd().format(leave.appliedDate),
            Icons.calendar_today_outlined,
            colorScheme,
          ),
          SizedBox(height: 16),
          _buildDetailRow(
            'Action By',
            leave.actionBy,
            Icons.person_outline,
            colorScheme,
          ),
          if (leave.action.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailRow(
              'Action',
              leave.action,
              Icons.info_outline,
              colorScheme,
            ),
          ],
          SizedBox(height: 20),
          Divider(color: colorScheme.outline.withOpacity(0.1)),
          SizedBox(height: 16),
          _buildActionButtons(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurface.withOpacity(0.5)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: 18),
            label: Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline, size: 18),
            label: Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getLeaveTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sick leave':
        return Icons.sick;
      case 'annual leave':
      case 'vacation':
        return Icons.beach_access;
      case 'personal leave':
        return Icons.person;
      case 'maternity leave':
        return Icons.child_care;
      case 'paternity leave':
        return Icons.family_restroom;
      case 'emergency leave':
        return Icons.emergency;
      case 'study leave':
        return Icons.school;
      default:
        return Icons.event_available;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'new':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
