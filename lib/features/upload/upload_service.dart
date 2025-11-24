import 'dart:io';

abstract class UploadService {
  /// Uploads a selfie (camera only)
  Future<String> uploadSelfie({
    required File file,
    required String userId,
  });

  /// Uploads a document (image or PDF)
  Future<String> uploadDocument({
    required File file,
    required String userId,
  });
}
