import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class SavedDownload {
  final String fileName;
  final String displayPath;
  final String? filePath;
  final String? uri;
  final String mimeType;

  const SavedDownload({
    required this.fileName,
    required this.displayPath,
    required this.mimeType,
    this.filePath,
    this.uri,
  });
}

class DownloadSaver {
  static const MethodChannel _channel = MethodChannel(
    'quantum_dashboard/downloads',
  );

  static Future<SavedDownload> saveBytesToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('Unable to save an empty file.');
    }

    final safeFileName = _safeFileName(fileName);

    if (Platform.isAndroid) {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveBytesToDownloads',
        {'bytes': bytes, 'fileName': safeFileName, 'mimeType': mimeType},
      );

      if (result == null) {
        throw Exception('Unable to save file to Downloads.');
      }

      return SavedDownload(
        fileName: result['fileName']?.toString() ?? safeFileName,
        displayPath:
            result['displayPath']?.toString() ?? 'Downloads/$safeFileName',
        filePath: result['filePath']?.toString(),
        uri: result['uri']?.toString(),
        mimeType: result['mimeType']?.toString() ?? mimeType,
      );
    }

    final directory =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$safeFileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return SavedDownload(
      fileName: safeFileName,
      displayPath: filePath,
      filePath: filePath,
      mimeType: mimeType,
    );
  }

  static Future<OpenResult> openDownload(SavedDownload download) async {
    if (Platform.isAndroid &&
        download.uri != null &&
        download.uri!.isNotEmpty) {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'openDownloadUri',
        {'uri': download.uri, 'mimeType': download.mimeType},
      );

      final opened = result?['opened'] == true;
      return OpenResult(
        type: opened ? ResultType.done : ResultType.noAppToOpen,
        message: result?['message']?.toString() ?? '',
      );
    }

    if (download.filePath == null || download.filePath!.isEmpty) {
      return OpenResult(
        type: ResultType.fileNotFound,
        message: 'File path not found.',
      );
    }

    return OpenFilex.open(download.filePath!);
  }

  static void showSavedSnackBar({
    required BuildContext context,
    required SavedDownload download,
    String message = 'Downloaded successfully',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message\nLocation: ${download.displayPath}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () async {
            final result = await openDownload(download);
            if (!context.mounted || result.type == ResultType.done) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.message.trim().isEmpty
                      ? 'Unable to open ${download.fileName}'
                      : result.message,
                ),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ),
    );
  }

  static String _safeFileName(String fileName) {
    final trimmed = fileName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return trimmed.isEmpty ? 'download' : trimmed;
  }
}
