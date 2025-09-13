import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quantum_dashboard/models/leave_model.dart';
import 'package:quantum_dashboard/utils/text_styles.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: _buildTileTitle(),
        subtitle: _buildTileSubtitle(),
        trailing: _buildStatusChip(),
        children: [
          _buildExpandedContent(context),
        ],
      ),
    );
  }

  Widget _buildTileTitle() {
    return Row(
      children: [
        Icon(
          _getLeaveTypeIcon(leave.type),
          color: _getStatusColor(leave.status),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            leave.type,
            style: AppTextStyles.subheading.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileSubtitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${DateFormat.yMMMd().format(leave.fromDate)} - ${DateFormat.yMMMd().format(leave.toDate)}',
        style: AppTextStyles.body.copyWith(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(leave.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(leave.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        leave.status.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: _getStatusColor(leave.status),
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Duration', '${leave.totalDays} day${leave.totalDays != 1 ? 's' : ''}'),
          const SizedBox(height: 8),
          _buildDetailRow('Reason', leave.reason),
          const SizedBox(height: 8),
          _buildDetailRow('Applied Date', DateFormat.yMMMd().format(leave.appliedDate)),
          const SizedBox(height: 8),
          _buildDetailRow('Action By', leave.actionBy),
          if (leave.action.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Action', leave.action),
          ],
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.edit,
            label: 'Edit',
            color: Colors.blue,
            onPressed: onEdit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.delete,
            label: 'Delete',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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
