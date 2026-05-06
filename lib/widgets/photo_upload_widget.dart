import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quantum_dashboard/models/user_model.dart';

class PhotoUploadWidget extends StatelessWidget {
  final Employee? employee;
  final String? employeeId;
  final Function(Employee)? onPhotoUploaded;
  final bool isAdminMode;
  final double size;

  const PhotoUploadWidget({
    super.key,
    this.employee,
    this.employeeId,
    this.onPhotoUploaded,
    this.isAdminMode = false,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        color: Colors.grey[100],
      ),
      child: _buildPhotoContent(),
    );
  }

  Widget _buildPhotoContent() {
    final profileImage = employee?.profileImage.trim() ?? '';
    if (profileImage.isEmpty) {
      return _buildPlaceholder();
    }

    if (profileImage.startsWith('data:image')) {
      try {
        final bytes = base64Decode(profileImage.split(',').last);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    final uri = Uri.tryParse(profileImage);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return ClipOval(
        child: Image.network(
          profileImage,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final initial = employee?.firstName.isNotEmpty == true
        ? employee!.firstName[0].toUpperCase()
        : 'Q';

    return ClipOval(
      child: Container(
        color: Colors.blue.shade700,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.34,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
