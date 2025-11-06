import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/photo_service.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PhotoUploadWidget extends StatefulWidget {
  final Employee? employee;
  final String? employeeId;
  final Function(Employee)? onPhotoUploaded;
  final bool isAdminMode;
  final double size;

  const PhotoUploadWidget({
    Key? key,
    this.employee,
    this.employeeId,
    this.onPhotoUploaded,
    this.isAdminMode = false,
    this.size = 120,
  }) : super(key: key);

  @override
  _PhotoUploadWidgetState createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final PhotoService _photoService = PhotoService();
  bool _isUploading = false;
  File? _imageFile;
  ScaffoldMessengerState? _scaffoldMessenger;
  AuthProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!widget.isAdminMode) {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 2),
              color: Colors.grey[100],
            ),
            child: _buildPhotoContent(),
          ),
        ),
        SizedBox(height: 12),
        if (widget.employee?.profileImage != null &&
            widget.employee!.profileImage.isNotEmpty)
          TextButton.icon(
            onPressed: _isUploading ? null : _deletePhoto,
            icon: Icon(Icons.delete, size: 16),
            label: Text('Remove Photo', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
      ],
    );
  }

  Widget _buildPhotoContent() {
    if (_isUploading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_imageFile != null) {
      return ClipOval(
        child: Image.file(
          _imageFile!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (widget.employee?.profileImage != null &&
        widget.employee!.profileImage.isNotEmpty) {
      final photoUrl = _photoService.getPhotoUrl(widget.employee!.profileImage);
      // Support data URL directly
      if (photoUrl.startsWith('data:image')) {
        final base64Part = photoUrl.split(',').last;
        try {
          final bytes = base64Decode(base64Part);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {
          // Fallback to placeholder if decode fails
          return _buildPlaceholder();
        }
      }
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? (loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!)
                    : null,
              ),
            );
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt,
          size: widget.size * 0.3,
          color: Colors.grey[600],
        ),
        SizedBox(height: 4),
        Text(
          'Add Photo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    if (_isUploading) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (widget.employee?.profileImage != null &&
                  widget.employee!.profileImage.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePhoto();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _photoService.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        await _uploadPhoto(image.path);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadPhoto(String imagePath) async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      Employee updatedEmployee;

      if (widget.isAdminMode && widget.employeeId != null) {
        updatedEmployee = await _photoService.uploadEmployeePhoto(
          widget.employeeId!,
          imagePath,
        );
      } else {
        if (!mounted || _authProvider == null) return;
        final current = _authProvider!.user!;
        // Immediately update local profile image with compressed data URL
        final String dataUrl = await _photoService.buildCompressedDataUrl(
          imagePath,
        );
        if (!mounted) return;
        _authProvider!.setUser(current.copyWith(profileImage: dataUrl));
        updatedEmployee = await _photoService.uploadProfilePhoto(
          imagePath,
          employeeMongoId: current.id,
          employeeId: current.employeeId,
        );
      }

      if (!mounted) return;
      setState(() {
        _imageFile = null;
        _isUploading = false;
      });

      widget.onPhotoUploaded?.call(updatedEmployee);

      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Photo uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _imageFile = null;
        _isUploading = false;
      });
      _showError('Failed to upload photo: $e');
    }
  }

  Future<void> _deletePhoto() async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      if (!mounted || _authProvider == null) return;
      final current = _authProvider!.user!;
      // Immediately clear local profile image
      _authProvider!.setUser(current.copyWith(profileImage: ''));
      final updatedEmployee = await _photoService.deleteProfilePhoto(
        employeeMongoId: current.id,
        employeeId: current.employeeId,
      );

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      widget.onPhotoUploaded?.call(updatedEmployee);

      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Photo removed successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      _showError('Failed to remove photo: $e');
    }
  }

  void _showError(String message) {
    if (!mounted || _scaffoldMessenger == null) return;
    _scaffoldMessenger!.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
