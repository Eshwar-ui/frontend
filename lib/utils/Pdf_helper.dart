import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:quantum_dashboard/utils/download_saver.dart';

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
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Downloading payslip...'),
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
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Storage permission is required to download files. Please grant permission in settings.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      if (!context.mounted) return;
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

    if (!contentType.contains('pdf')) {
      if (!context.mounted) return;
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

    if (response.bodyBytes.isNotEmpty) {
      final download = await DownloadSaver.saveBytesToDownloads(
        bytes: Uint8List.fromList(response.bodyBytes),
        fileName: fileName.toLowerCase().endsWith('.pdf')
            ? fileName
            : '$fileName.pdf',
        mimeType: 'application/pdf',
      );

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      DownloadSaver.showSavedSnackBar(
        context: context,
        download: download,
        message: 'Payslip downloaded successfully',
      );
    } else {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloaded file is empty. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
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
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 30;
  } catch (e) {
    return false;
  }
}
