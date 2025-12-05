//
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../../models/call_log_model.dart';
// import '../../call/services/call_service.dart';
//
// class CallHistoryScreen extends StatelessWidget {
//   const CallHistoryScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser!.uid;
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Call History")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance
//             .collection("call_logs")
//             .where("callerId", isEqualTo: uid)
//             .orderBy("timestamp", descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//
//           final docs = snapshot.data!.docs;
//
//           if (docs.isEmpty) {
//             return const Center(child: Text("No call history"));
//           }
//
//           return ListView.builder(
//             itemCount: docs.length,
//             itemBuilder: (_, index) {
//               final entry = CallLogEntry.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
//
//               final isMeCaller = entry.callerId == uid;
//               final callTypeIcon = entry.isMissed
//                   ? Icons.call_missed
//                   : isMeCaller
//                   ? Icons.call_made
//                   : Icons.call_received;
//
//               return ListTile(
//                 leading: Icon(
//                   callTypeIcon,
//                   color: entry.isMissed ? Colors.red : Colors.green,
//                 ),
//                 title: Text(entry.isGroup ? "Group Call" : entry.receiverName),
//                 subtitle: Text(
//                   entry.isMissed
//                       ? "Missed"
//                       : entry.duration == 0
//                       ? "Ringing..."
//                       : "Duration: ${entry.duration}s",
//                 ),
//                 trailing: Icon(entry.isVideo ? Icons.videocam : Icons.call),
//                 onTap: () => _onCallTap(context, entry),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   void _onCallTap(BuildContext context, CallLogEntry entry) {
//     if (entry.isGroup) {
//       CallService.instance.startGroupVoiceCall(
//         context: context,
//         groupId: entry.groupId,
//       );
//     } else {
//       // Show WhatsApp-style bottom sheet
//       showModalBottomSheet(
//         context: context,
//         builder: (_) => Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.call),
//               title: const Text("Voice Call"),
//               onTap: () {
//                 CallService.instance.startP2PVoiceCall(
//                   context: context,
//                   groupId: entry.groupId,
//                   peerId: entry.receiverId,
//                 );
//                 Navigator.pop(context);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.videocam),
//               title: const Text("Video Call"),
//               onTap: () {
//                 CallService.instance.startP2PVideoCall(
//                   context: context,
//                   groupId: entry.groupId,
//                   peerId: entry.receiverId,
//                 );
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         ),
//       );
//     }
//   }
// }
//
//
//




import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Call History"),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("active_calls")
            .where("participants", arrayContains: uid)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No calls yet.",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final type = data["type"] ?? "group_voice";
              final startedBy = data["startedBy"] ?? "";
              final List missed = (data["missed"] ?? []) as List;
              final createdAt = (data["createdAt"] as Timestamp?)?.toDate();

              final isVideo = type.toString().contains("video");
              final isGroup = type.toString().startsWith("group_");
              final isMissed = missed.contains(uid);
              final isOutgoing = startedBy == uid;

              IconData leadingIcon =
              isVideo ? Icons.videocam : Icons.call;
              Color iconColor =
              isMissed ? Colors.redAccent : Colors.greenAccent;

              String title;
              if (isMissed) {
                title = isOutgoing ? "Missed outgoing call" : "Missed call";
              } else {
                if (isOutgoing) {
                  title = isGroup ? "Outgoing group call" : "Outgoing call";
                } else {
                  title = isGroup ? "Incoming group call" : "Incoming call";
                }
              }

              return ListTile(
                leading: Icon(leadingIcon, color: iconColor),
                title: Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  createdAt?.toLocal().toString() ?? "",
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Icon(
                  isMissed
                      ? Icons.call_missed
                      : (isOutgoing
                      ? Icons.call_made
                      : Icons.call_received),
                  color: iconColor,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
