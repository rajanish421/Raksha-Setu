import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../profile/screens/image_viewer_screen.dart';
import '../../profile/screens/pdf_viewer_screen.dart';

class FamilyMemberDetailsScreen extends StatefulWidget {
  final UserModel user;

  const FamilyMemberDetailsScreen({super.key, required this.user});

  @override
  State<FamilyMemberDetailsScreen> createState() =>
      _FamilyMemberDetailsScreenState();
}

class _FamilyMemberDetailsScreenState extends State<FamilyMemberDetailsScreen> {
  bool _downloading = false;

  Future<void> _openDocument(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No document uploaded")),
      );
      return;
    }

    setState(() => _downloading = true);

    try {
      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last.split("?").first; // safe filename
      final filePath = "${dir.path}/$fileName";
      final file = File(filePath);

      // Download only if not existing
      if (!await file.exists()) {
        await Dio().download(url, filePath);
      }

      setState(() => _downloading = false);

      if (filePath.toLowerCase().endsWith(".pdf")) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(filePath: filePath),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(filePath: filePath),
          ),
        );
      }
    } catch (e) {
      setState(() => _downloading = false);
      print("❌ Document open error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to open document: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// 📌 Photo with Status Border
          Center(
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: user.status == "approved"
                      ? Colors.green
                      : user.status == "pending"
                      ? Colors.orange
                      : Colors.red,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundImage: user.selfieUrl.isNotEmpty
                    ? NetworkImage(user.selfieUrl)
                    : null,
                child: user.selfieUrl.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _infoTile("Name", user.fullName),
          _infoTile("Relationship", user.relationship ?? "-"),
          _infoTile("Phone", user.phone ?? "-"),
          _infoTile("Service Number (Linked Soldier)", user.serviceNumber ?? "-"),

          const SizedBox(height: 20),

          /// 📎 Document Viewer Button
          ElevatedButton.icon(
            onPressed: _downloading
                ? null
                : () => _openDocument(context, user.documentUrl),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_downloading
                ? "Opening..."
                : "View Submitted Document"),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
        ],
      ),
    );
  }
}
