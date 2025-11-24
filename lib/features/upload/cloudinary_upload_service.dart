import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'upload_service.dart';

class CloudinaryUploadService implements UploadService {
  final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Common upload function
  Future<String> _uploadFile({
    required File file,
    required String folder,
  }) async {
    final url =
        "https://api.cloudinary.com/v1_1/$cloudName/auto/upload"; // auto detects image/pdf

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = folder;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: $responseBody');
    }

    final json = jsonDecode(responseBody);
    return json['secure_url'];
  }

  @override
  Future<String> uploadSelfie({
    required File file,
    required String userId,
  }) async {
    return await _uploadFile(
      file: file,
      folder: "selfies/$userId",
    );
  }

  @override
  Future<String> uploadDocument({
    required File file,
    required String userId,
  }) async {
    return await _uploadFile(
      file: file,
      folder: "documents/$userId",
    );
  }
}
