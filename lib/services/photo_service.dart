import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';
import 'package:quantum_dashboard/services/employee_service.dart';

class PhotoService extends ApiService {
  final ImagePicker _picker = ImagePicker();
  // Build a compressed data URL from an image path
  Future<String> buildCompressedDataUrl(String imagePath) async {
    final Uint8List? compressedBytes =
        await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: 600,
      minHeight: 600,
      quality: 40,
    );

    if (compressedBytes == null) {
      throw Exception("Image compression failed");
    }

    final String base64Data = base64Encode(compressedBytes);
    return 'data:image/jpeg;base64,$base64Data';
  }

  // Pick image from gallery or camera
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  // Upload profile photo for current user
  Future<Employee> uploadProfilePhoto(
    String imagePath, {
    required String employeeMongoId,
    required String employeeId,
  }) async {
    try {
      // Build compressed data URL
      final String dataUrl = await buildCompressedDataUrl(imagePath);

      final employeeService = EmployeeService();
      await employeeService.updateEmployee(employeeMongoId, {
        'profileImage': dataUrl,
      });

      // Re-fetch the employee to get latest data
      final updated = await employeeService.getEmployee(employeeId);
      return updated;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Upload photo for specific employee (Admin/HR only)
  Future<Employee> uploadEmployeePhoto(
    String employeeId,
    String imagePath,
  ) async {
    try {
      final employeeService = EmployeeService();
      // Get full employee to retrieve Mongo _id
      final employee = await employeeService.getEmployee(employeeId);
      return uploadProfilePhoto(
        imagePath,
        employeeMongoId: employee.id,
        employeeId: employee.employeeId,
      );
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Delete profile photo
  Future<Employee> deleteProfilePhoto({
    required String employeeMongoId,
    required String employeeId,
  }) async {
    try {
      final employeeService = EmployeeService();
      await employeeService.updateEmployee(employeeMongoId, {
        'profileImage': '',
      });
      final updated = await employeeService.getEmployee(employeeId);
      return updated;
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  // Get full photo URL
  String getPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return '';
    }
    if (photoPath.startsWith('http')) {
      return photoPath;
    }
    if (photoPath.startsWith('data:image')) {
      return photoPath; // Will be handled specially by the caller
    }
    return '${ApiService.baseUrl}$photoPath';
  }
}
