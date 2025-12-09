//
//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:provider/provider.dart';
// import '../providers/user_provider.dart';
// import '../utils/route_names.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigate();
//   }
//
//   Future<void> _navigate() async {
//     await Future.delayed(const Duration(seconds: 2)); // show splash
//
//     final auth = FirebaseAuth.instance;
//     final user = auth.currentUser;
//
//     if (user == null) {
//       // 🔹 User not logged in → Login/Welcome screen
//       Navigator.pushReplacementNamed(context, RouteNames.welcome);
//     } else {
//       // 🔹 User already logged in → load user profile then go Home
//       final provider = Provider.of<UserProvider>(context, listen: false);
//
//       await provider.refresh(); // fetch Firestore user info
//       Navigator.pushReplacementNamed(context, RouteNames.home);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }

//

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../constants/app_colors.dart';
import '../providers/user_provider.dart';
import '../utils/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    // Small delay to show splash (optional)
    await Future.delayed(const Duration(seconds: 2));

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      // 🔹 User NOT logged in → go to Welcome/Login
      Navigator.pushReplacementNamed(context, RouteNames.welcome);
      return;
    }

    // 🔹 User logged in → ask for biometric auth
    final ok = await _authenticateWithBiometrics();

    if (!mounted) return;

    if (ok) {
      // ✅ Biometric success → load Firestore profile and go Home
      final provider = Provider.of<UserProvider>(context, listen: false);
      await provider.refresh();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.home);
    } else {
      // ❌ Biometric failed/cancelled → log out and go to Welcome
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.welcome);
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      // Check if device supports biometrics
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheck = await _localAuth.canCheckBiometrics;

      debugPrint("📌 Device Biometric Supported: $isDeviceSupported");
      debugPrint("📌 Biometrics Available Check: $canCheck");

      // 🔍 Fetch available biometric types
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint("🔍 Available Biometrics Found: $availableBiometrics");

      // Logging biometric type individually
      if (availableBiometrics.contains(BiometricType.face)) {
        debugPrint("🟢 Face Unlock Available");
      } else {
        debugPrint("❌ Face Unlock NOT Available");
      }

      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        debugPrint("🟢 Fingerprint Available");
      } else {
        debugPrint("❌ Fingerprint NOT Available");
      }

      if (!isDeviceSupported || !canCheck) {
        debugPrint("⚠️ Biometrics NOT supported, skipping authentication.");
        return true;
      }

      // Authenticate user
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: "Authenticate to access Raksha Setu",
        biometricOnly: true,
      );

      debugPrint("🔐 Authentication Result: $didAuthenticate");

      return didAuthenticate;
    } catch (e) {
      debugPrint("❌ Biometric Error: $e");
      return false;
    }
  }



  // Future<bool> _authenticateWithBiometrics() async {
  //   try {
  //     // Check if device supports biometrics
  //     final isDeviceSupported = await _localAuth.isDeviceSupported();
  //     final canCheck = await _localAuth.canCheckBiometrics;
  //
  //     if (!isDeviceSupported || !canCheck) {
  //       // If no biometrics → just allow access (or you can force logout instead)
  //       return true;
  //     }
  //
  //     // ✅ OLD API style – no AuthenticationOptions
  //     final bool didAuthenticate = await _localAuth.authenticate(
  //       localizedReason: "Authenticate to access Raksha Setu",
  //       biometricOnly: true,
  //     );
  //
  //     return didAuthenticate;
  //   } catch (e) {
  //     debugPrint("Biometric error---------------------------------------------->: $e");
  //     // In case of any error, you can choose:
  //     // - return true → allow access
  //     // - return false → force logout
  //     return false;
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo placeholder – later use real logo
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 52,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Raksha Setu',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Communication for\nSoldiers, Veterans & Families',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


