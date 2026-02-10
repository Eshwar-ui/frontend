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

  // Request storage permission for Android (only for older versions)
  if (Platform.isAndroid) {
    if (!await _isAndroid11OrAbove()) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
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
    // Android 11+ uses scoped storage - app-specific directory needs no special permission
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
      // Use app-specific external storage directory
      // This works without MANAGE_EXTERNAL_STORAGE on Android 11+
      // And with standard storage permission on older versions
      print('Using app-specific external storage');
      dir = await getExternalStorageDirectory();
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


Future<bool> _isAndroid11OrAbove() async {
  if (!Platform.isAndroid) return false;
  try {
    // Try to check manageExternalStorage status
    // If this permission exists, it means Android 11+ (API 30+)
    await Permission.manageExternalStorage.status;
    return true;
  } catch (e) {
    // If permission doesn't exist or throws error, it's likely Android 10 or below
    return false;
  }
}
