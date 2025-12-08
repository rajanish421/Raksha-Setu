// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class CreateSoldierGroupDialog extends StatefulWidget {
//   const CreateSoldierGroupDialog({super.key});
//
//   @override
//   State<CreateSoldierGroupDialog> createState() => _CreateSoldierGroupDialogState();
// }
//
// class _CreateSoldierGroupDialogState extends State<CreateSoldierGroupDialog> {
//   final TextEditingController nameCtrl = TextEditingController();
//   List<String> selected = [];
//   String search = "";
//
//   @override
//   Widget build(BuildContext context) {
//     final uid = FirebaseAuth.instance.currentUser!.uid;
//
//     return Dialog(
//       backgroundColor: Colors.black,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: SizedBox(
//           width: 330,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text("Create Family Group", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//
//               TextField(
//                 controller: nameCtrl,
//                 decoration: const InputDecoration(labelText: "Group Name"),
//               ),
//
//               const SizedBox(height: 12),
//               const Text("Select Family Members"),
//
//               Expanded(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance
//                       .collection("users")
//                       .where("linkedSoldier", isEqualTo: uid)
//                       .where("status", isEqualTo: "approved")
//                       .snapshots(),
//                   builder: (_, snap) {
//                     if (!snap.hasData) return const Center(child: CircularProgressIndicator());
//
//                     final docs = snap.data!.docs;
//
//                     return ListView(
//                       children: docs.map((d) {
//                         return CheckboxListTile(
//                           value: selected.contains(d.id),
//                           title: Text(d["fullName"]),
//                           onChanged: (val) => setState(() {
//                             val! ? selected.add(d.id) : selected.remove(d.id);
//                           }),
//                         );
//                       }).toList(),
//                     );
//                   },
//                 ),
//               ),
//
//               ElevatedButton(
//                 child: const Text("Create"),
//                 onPressed: () async {
//                   await FirebaseFirestore.instance.collection("groups").add({
//                     "name": nameCtrl.text.trim(),
//                     "members": [uid, ...selected],
//                     "officers": [],
//                     "createdBy": uid,
//                     "type": "family",
//                     "createdAt": Timestamp.now()
//                   });
//
//                   Navigator.pop(context, true);
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
