import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadAndOpenPdf(
  String url,
  String fileName,
  BuildContext context,
) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading payslip...'),
          ],
        ),
      );
    },
  );

  // Request storage permission for Android
  if (Platform.isAndroid) {
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Storage permission is required to download files. Please grant permission in settings.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }
  }

  try {
    // Download file
    print('Downloading PDF from: $url');
    final response = await http.get(Uri.parse(url));
    print('Response status: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body length: ${response.bodyBytes.length}');

    if (response.statusCode != 200) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download PDF: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check content type
    final contentType = response.headers['content-type'] ?? '';
    print('Content-Type: $contentType');

    if (!contentType.contains('pdf')) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Downloaded file is not a valid PDF. Got: $contentType',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get storage directory
    Directory? dir;
    if (Platform.isAndroid) {
      // Check if we have MANAGE_EXTERNAL_STORAGE permission for Downloads folder
      final manageExternalStorageStatus =
          await Permission.manageExternalStorage.status;
      print(
        'MANAGE_EXTERNAL_STORAGE status for directory: $manageExternalStorageStatus',
      );

      if (manageExternalStorageStatus.isGranted) {
        dir = Directory('/storage/emulated/0/Download');
        print('Trying Downloads directory: ${dir.path}');
        if (!await dir.exists()) {
          print('Downloads directory does not exist, using external storage');
          dir = await getExternalStorageDirectory();
        }
      } else {
        // Use app-specific external storage directory
        print('Using app-specific external storage');
        dir = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      print('Using iOS documents directory');
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getTemporaryDirectory();
    }

    if (dir == null) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access storage directory'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Selected directory: ${dir.path}');

    final filePath = "${dir.path}/$fileName.pdf";
    final file = File(filePath);

    if (response.bodyBytes.isNotEmpty) {
      await file.writeAsBytes(response.bodyBytes);
      print(
        'File written successfully. File size: ${await file.length()} bytes',
      );

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payslip downloaded successfully!\nLocation: ${dir.path}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Open file in default PDF viewer
      try {
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open PDF: ${result.message}'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded file is empty. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    Navigator.of(context).pop(); // Close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download failed: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<bool> _requestStoragePermission() async {
  print('Requesting storage permissions...');

  // Try to request MANAGE_EXTERNAL_STORAGE first for Android 11+
  final manageExternalStorageStatus = await Permission.manageExternalStorage
      .request();
  print('MANAGE_EXTERNAL_STORAGE status: $manageExternalStorageStatus');

  if (manageExternalStorageStatus.isGranted) {
    print('MANAGE_EXTERNAL_STORAGE granted');
    return true;
  }

  // If MANAGE_EXTERNAL_STORAGE is not available or denied, try traditional storage permission
  final storageStatus = await Permission.storage.request();
  print('Storage permission status: $storageStatus');

  if (storageStatus.isGranted) {
    print('Storage permission granted');
    return true;
  }

  // If both are denied, we can still use app-specific storage
  print('Using app-specific storage (permissions denied)');
  return true; // Allow downloads to app-specific directory
}
