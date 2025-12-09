// import 'package:flutter/material.dart';
// import '../../../constants/app_colors.dart';
// import '../../../utils/route_names.dart';
//
// class PendingApprovalScreen extends StatelessWidget {
//   const PendingApprovalScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.security, size: 90, color: AppColors.accent),
//                 const SizedBox(height: 16),
//                 Text(
//                   "Account Under Review",
//                   style: textTheme.headlineSmall,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "HQ is verifying your identity.\n"
//                       "You will be notified once approved.",
//                   textAlign: TextAlign.center,
//                   style: textTheme.bodyMedium,
//                 ),
//                 const SizedBox(height: 24),
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pushNamedAndRemoveUntil(
//                       context,
//                       RouteNames.login,
//                           (r) => false,
//                     );
//                   },
//                   child: const Text("Logout"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../constants/app_colors.dart';
import '../../../utils/route_names.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  String status = "loading";
  StreamSubscription<DocumentSnapshot>? listener;

  @override
  void initState() {
    super.initState();
    _listenStatusLive();
  }

  @override
  void dispose() {
    listener?.cancel();
    super.dispose();
  }

  /// 🔄 Live Firestore listener
  void _listenStatusLive() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    listener = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final value = snap.data()?["approvalStatus"]?.toString().toLowerCase() ?? "pending";
      setState(() => status = value);

      if (value == "approved") {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pushReplacementNamed(context, RouteNames.home);
        });
      }
    });
  }

  /// 🟡 Manual Refresh
  Future<void> _refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    setState(() {
      status = doc.data()?["approvalStatus"]?.toString().toLowerCase() ?? "pending";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (status == "loading") {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    /// Status text to show
    final messages = {
      "pending": "Your profile is submitted.\nHQ will review shortly.",
      "verifying": "Your identity is being verified.\nPlease wait...",
      "approved": "Your identity is verified.\nRedirecting...",
      "rejected": "Your request was rejected.\nContact support.",
    };

    /// Status colors
    final colors = {
      "pending": Colors.orangeAccent,
      "verifying": Colors.blueAccent,
      "approved": Colors.greenAccent,
      "rejected": Colors.redAccent,
    };

    /// Clean working Lottie URLs
    final animations = {
      "pending": "https://lottie.host/91e31fb4-1a53-4e48-abd5-0871670fba4b/3QqU8s6u6y.json",
      "verifying": "https://lottie.host/51c8535c-a0aa-42e4-a048-7b07e3691242/m7jEhcU4bX.json",
      "approved": "https://lottie.host/f9e09caa-8517-4f5c-97ad-f58b0f6285e2/9nKSQZqT3W.json",
      "rejected": "https://lottie.host/77507d37-978e-431c-8347-4d2b93a9f5f5/VvAmW4q5b0.json",
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                /// 🔥 Animation
                SizedBox(
                  height: 180,
                  child: Lottie.network(
                    animations[status]!,
                    repeat: status != "approved",
                    errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: Colors.white54, size: 100),
                  ),
                ),

                const SizedBox(height: 18),

                /// STATUS TEXT
                Text(
                  status.toUpperCase(),
                  style: textTheme.headlineMedium?.copyWith(
                    color: colors[status],
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                /// MESSAGE
                Text(
                  messages[status]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                ),

                const SizedBox(height: 30),

                /// 🔄 Refresh Button
                ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Status"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// Logout Button
                TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, RouteNames.login, (_) => false);
                    }
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
