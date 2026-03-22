import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:eventbridge/core/network/api_service.dart';

/// Handles uploading files to S3 via presigned URLs
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  static UploadService get instance => _instance;

  final _plainDio = Dio(); // No base URL — uses the presigned S3 URL directly

  /// Upload a single file. Returns the public file URL on S3.
  /// [bytes] - the file bytes to upload
  /// [fileName] - original file name
  /// [contentType] - MIME type e.g. 'image/jpeg'
  /// [folder] - S3 folder e.g. 'avatars', 'gallery', 'documents'
  Future<String> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String folder = 'uploads',
  }) async {
    // 1. Get presigned URL from backend
    final api = ApiService.instance;
    final presigned = await api.getPresignedUrl(
      fileName: fileName,
      contentType: contentType,
      folder: folder,
    );

    final uploadUrl = presigned['uploadUrl'] as String;
    final fileUrl = presigned['fileUrl'] as String;

    // 2. Upload directly to S3
    await _plainDio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': bytes.length,
        },
      ),
    );

    return fileUrl;
  }

  /// Upload multiple files. Returns list of public file URLs.
  Future<List<String>> uploadFiles({
    required List<UploadFileData> files,
    String folder = 'uploads',
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadFile(
        bytes: file.bytes,
        fileName: file.fileName,
        contentType: file.contentType,
        folder: folder,
      );
      urls.add(url);
    }
    return urls;
  }
}

class UploadFileData {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  UploadFileData({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}
