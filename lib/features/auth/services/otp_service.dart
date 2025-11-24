import 'package:firebase_auth/firebase_auth.dart';

abstract class OtpService {
  Future<String> sendOtp({required String phoneNumber});
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });
}
