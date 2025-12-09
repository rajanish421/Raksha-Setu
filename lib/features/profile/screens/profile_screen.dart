import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:raksha_setu/features/profile/screens/pdf_viewer_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/route_names.dart';
import '../../auth/services/auth_service.dart';
import '../../status/active_user_service.dart';
import 'image_viewer_screen.dart';
 import 'package:dio/dio.dart';




class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Open uploaded document (PDF or Image)

  Future<void> _openDocument(String url, BuildContext context) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = "${dir.path}/$fileName";

      final file = File(filePath);

      // Download only if not cached
      if (!await file.exists()) {
        await Dio().download(url, filePath);
      }

      if (filePath.toLowerCase().endsWith(".pdf")) {
        // 📄 Open PDF Viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(filePath: filePath),
          ),
        );
      } else {
        // 🖼 Open Image Viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(filePath: filePath),
          ),
        );
      }

    } catch (e) {
      print("❌ Document open error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Unable to open document.")),
      );
    }
  }


  /// Logout and reset OTP state safely
  Future<void> _logout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null) {
        // Check linked providers
        final providers = user.providerData.map((p) => p.providerId).toList();

        if (providers.contains('phone')) {
          // Remove phone link so next login requires OTP again
          await user.unlink('phone');
          print("📌 Phone authentication unlinked for next login verification.");
        } else {
          print("ℹ No phone provider linked, nothing to unlink.");
        }
      }
    } catch (e) {
      print("⚠ Error while unlinking phone provider: $e");
    }

    // Sign out Firebase completely
    await AuthService.instance.signOut();

    await ActiveUserService.instance.markOffline();  // 👈 mark user inactive

    // Clear your local state provider (important)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.clear();

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
            (route) => false,
      );
    }
  }


  // without logout button

  //
  // /// Logout
  // Future<void> _logout(BuildContext context) async {
  //   await AuthService.instance.signOut();
  //
  //   if (context.mounted) {
  //     Navigator.pushNamedAndRemoveUntil(
  //       context,
  //       RouteNames.login,
  //           (route) => false,
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      userProvider.refresh();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF101417),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------- HEADER ------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.tealAccent, width: 1.2),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: NetworkImage(user.selfieUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${user.rank} • ${user.unit}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  _badge(user.status),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ---------- DETAILS ----------
            if (user.serviceNumber != null)
              _detailTile("Service Number", user.serviceNumber!),

            _detailTile("Role", user.role),
            _detailTile("Phone Number", user.phone),
            _detailTile("User ID", user.userId),

            const SizedBox(height: 20),

            // ---------- DOCUMENT BUTTON ----------
            if (user.documentUrl.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("View Verified Document"),
                onPressed: () => _openDocument(user.documentUrl, context),
              ),

            const SizedBox(height: 40),

            // ---------- LOGOUT ----------
            TextButton(
              onPressed: () => _logout(context),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// UI Helper: User Info Tile
  Widget _detailTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white10,
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// UI Helper: Status Badge
  Widget _badge(String status) {
    Color color;
    String text;

    switch (status) {
      case "approved":
        color = Colors.greenAccent;
        text = "✔ Verified";
        break;
      case "pending":
        color = Colors.orangeAccent;
        text = "⏳ Pending Verification";
        break;
      default:
        color = Colors.redAccent;
        text = "❌ Not Verified";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
