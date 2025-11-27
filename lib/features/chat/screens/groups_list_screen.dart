import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../constants/app_colors.dart';
import 'chat_screen.dart';

class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});



  Future<void> _openChat(BuildContext context, String groupId, String groupName) async {
    final messagesRef = FirebaseFirestore.instance
        .collection("groups")
        .doc(groupId)
        .collection("messages");

    final snap = await messagesRef.limit(1).get();

    if (snap.docs.isEmpty) {
      // Create First System Message
      await messagesRef.add({
        "type": "system",
        "text": "🔐 Secure channel created. Communication is encrypted.",
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    // Navigate after initialization
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          groupId: groupId,
          groupName: groupName,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Secure Groups"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("groups")
            .where("members", arrayContains: uid) // only groups user belongs to
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No groups assigned.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final groupId = docs[i].id;
              final name = data["name"] ?? "Unknown Group";
              final members = (data["members"] as List).length;
              final officers = (data["officers"] as List).length;

              return ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  "$members members • $officers officers",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 18),
                onTap: () => _openChat(context, groupId, name),
              );
            },
          );
        },
      ),
    );
  }
}
