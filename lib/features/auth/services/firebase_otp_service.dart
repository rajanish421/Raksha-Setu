import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_service.dart';

class FirebaseOtpService implements OtpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<String> sendOtp({required String phoneNumber}) async {
    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // e.g., +91XXXXXXXXXX
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // We are not auto-signing-in with phone.
        // This callback can be left empty or used to link credential.
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(Exception(e.message ?? 'OTP failed'));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // If timeout, we can still use this verificationId if needed.
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }


  // without logout

  // @override
  // Future<void> verifyOtp({
  //   required String verificationId,
  //   required String smsCode,
  // }) async {
  //   final credential = PhoneAuthProvider.credential(
  //     verificationId: verificationId,
  //     smsCode: smsCode,
  //   );
  //
  //   final currentUser = _auth.currentUser;
  //
  //   try {
  //     if (currentUser != null) {
  //       // Link phone credential to the existing user (for stronger security)
  //       await currentUser.linkWithCredential(credential);
  //     } else {
  //       // Fallback: sign in with phone (should not normally happen in our flow)
  //       await _auth.signInWithCredential(credential);
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     print(
  //         "===================================================================================");
  //     print(e.toString());
  //     // If already linked, we can ignore that specific error
  //     if (e.code != 'provider-already-linked') {
  //       rethrow;
  //     }
  //   }


    // }
    //

    @override
    Future<void> verifyOtp({
      required String verificationId,
      required String smsCode,
    }) async {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final currentUser = _auth.currentUser;

      try {
        if (currentUser != null) {
          // Try linking OTP to logged-in account
          await currentUser.linkWithCredential(credential);
        } else {
          // First time login using OTP
          await _auth.signInWithCredential(credential);
        }

      } on FirebaseAuthException catch (e) {

        print("OTP ERROR: ${e.code}");

        // 👇 KEY PART: Skip OTP if already verified before
        if (e.code == 'provider-already-linked') {
          print("🔁 OTP already verified — skipping verification.");
          return; // <-- treat as success
        }

        // Other OTP/Mobile errors must still fail
        rethrow;
      }



  }
}
