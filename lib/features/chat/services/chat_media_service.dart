import 'dart:io';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMediaService {
  ChatMediaService._internal();
  static final ChatMediaService instance = ChatMediaService._internal();

  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? "";
  String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? "";

  // ---------------------- Upload Image ----------------------
  Future<String> uploadImage({
    required File file,
    required String groupId,
    required String senderId,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception("Cloudinary not configured in .env");
    }

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = "raksha_setu/$groupId/images"
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Image upload failed: $body");
    }

    final json = jsonDecode(body);
    return json['secure_url'];
  }

  // ---------------------- Upload Document ----------------------
  Future<String> uploadDocument({
    required File file,
    required String groupId,
    required String senderId,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception("Cloudinary not configured in .env");
    }

    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/raw/upload",
    );

    final request = http.MultipartRequest("POST", uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = "raksha_setu/$groupId/docs"
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Document upload failed: $body");
    }

    final json = jsonDecode(body);
    return json["secure_url"];

    // --- (Optional PDF Preview Fix) ---
    // url = url.replaceFirst("/raw/upload/", "/raw/upload/fl_attachment:false/");
    // url = "$url?inline=true&t=${DateTime.now().millisecondsSinceEpoch}";
    // return url;
  }
}
