import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eventbridge/core/network/api_service.dart';

class S3ImageUploader {
  final ApiService _apiService;

  S3ImageUploader(this._apiService);

  Future<String> upload(File file) async {
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final presigned = await _apiService.getPresignedUrl(
      fileName: fileName,
      contentType: 'image/jpeg',
      folder: 'chats',
    );
    final uploadUrl = (presigned['uploadUrl'] ?? '').toString();
    final publicUrl = (presigned['publicUrl'] ?? '').toString();
    if (uploadUrl.isEmpty) {
      throw Exception('Missing upload URL');
    }

    final response = await Dio().put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Length': file.lengthSync(),
          'Content-Type': 'image/jpeg',
        },
      ),
    );

    if (response.statusCode == 200) {
      return publicUrl.isNotEmpty ? publicUrl : uploadUrl.split('?').first;
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
