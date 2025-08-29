import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/api_service.dart';

class PhotoService extends ApiService {
  final ImagePicker _picker = ImagePicker();

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
      print('Error picking image: $e');
      return null;
    }
  }

  // Upload profile photo for current user
  Future<Employee> uploadProfilePhoto(String imagePath) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/profile/upload-photo');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);
      
      // Add file
      final file = await http.MultipartFile.fromPath(
        'profilePhoto',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return Employee.fromJson(data['user']);
      } else {
        final errorData = json.decode(responseData);
        throw Exception(errorData['message'] ?? 'Failed to upload photo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading profile photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Upload photo for specific employee (Admin/HR only)
  Future<Employee> uploadEmployeePhoto(String employeeId, String imagePath) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/profile/upload-photo/$employeeId');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);
      
      // Add file
      final file = await http.MultipartFile.fromPath(
        'profilePhoto',
        imagePath,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return Employee.fromJson(data['employee']);
      } else {
        final errorData = json.decode(responseData);
        throw Exception(errorData['message'] ?? 'Failed to upload photo: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading employee photo: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  // Delete profile photo
  Future<Employee> deleteProfilePhoto() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/api/profile/delete-photo'),
        headers: await getHeaders(),
      );

      final data = handleResponse(response);
      return Employee.fromJson(data['user']);
    } catch (e) {
      print('Error deleting profile photo: $e');
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
    return '${ApiService.baseUrl}$photoPath';
  }
}
