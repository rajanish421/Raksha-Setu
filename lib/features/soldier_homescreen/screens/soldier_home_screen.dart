// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../../models/user_model.dart';
// import '../../../models/family_group_model.dart';
//
// import '../services/family_group_service.dart';
// import '../services/family_management_service.dart';
// import '../services/user_service.dart';
//
// import '../widgets/create_family_group_dialog.dart';
// import '../widgets/family_group_tile.dart';
// import '../widgets/family_member_card.dart';
// import '../../../providers/user_provider.dart';
//
// class SoldierHomeScreen extends StatefulWidget {
//   const SoldierHomeScreen({super.key});
//
//   @override
//   State<SoldierHomeScreen> createState() => _SoldierHomeScreenState();
// }
//
// class _SoldierHomeScreenState extends State<SoldierHomeScreen> {
//   List<UserModel> familyMembers = [];
//   List<FamilyGroupModel> groups = [];
//   bool loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }
//
//   Future<void> _load() async {
//     final provider = context.read<UserProvider>();
//     final user = provider.user;
//
//     if (user == null) {
//       setState(() => loading = false);
//       return;
//     }
//
//     // Fetch using existing service logic
//     familyMembers = await UserService().getFamilyMembers(user.serviceNumber ?? "");
//     groups = await FamilyGroupService().getGroups(user.userId);
//
//     setState(() => loading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<UserProvider>();
//     final user = provider.user;
//
//     if (user == null) {
//       return const Scaffold(
//         body: Center(child: Text("Loading user...")),
//       );
//     }
//
//     if (loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Welcome, ${user.fullName}"),
//         actions: [
//           StreamBuilder<QuerySnapshot>(
//             stream: FirebaseFirestore.instance
//                 .collection("alerts")
//                 .where("receiverId", isEqualTo: user.userId)
//                 .where("status", isEqualTo: "unread")
//                 .snapshots(),
//             builder: (_, snap) {
//               int count = snap.data?.docs.length ?? 0;
//               return Stack(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.notifications),
//                     onPressed: () => Navigator.pushNamed(context, "/alerts"),
//                   ),
//                   if (count > 0)
//                     Positioned(
//                       right: 8,
//                       top: 8,
//                       child: CircleAvatar(
//                         radius: 9,
//                         backgroundColor: Colors.red,
//                         child: Text(
//                           "$count",
//                           style: const TextStyle(fontSize: 11, color: Colors.white),
//                         ),
//                       ),
//                     ),
//                 ],
//               );
//             },
//           )
//         ],
//       ),
//
//       body: RefreshIndicator(
//         onRefresh: _load,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//
//             /// 🟢 Family Members Section
//             Text("Family Members", style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 10),
//
//             if (familyMembers.isEmpty)
//               const Text("No family members linked yet.", style: TextStyle(color: Colors.white54))
//             else
//               ...familyMembers.map(
//                     (m) => FamilyMemberCard(
//                   user: m,
//                   onApprove: () async {
//                     await FamilyManagementService().approveMember(m.userId);
//                     _load();
//                   },
//                   onReject: () async {
//                     await FamilyManagementService().rejectMember(m.userId);
//                     _load();
//                   },
//                 ),
//               ),
//
//             const SizedBox(height: 25),
//
//             /// 🟡 Groups Section
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text("Family Groups", style: Theme.of(context).textTheme.titleLarge),
//                 IconButton(
//                   icon: const Icon(Icons.add_circle, color: Colors.yellowAccent),
//                   onPressed: () async {
//                     final created = await showDialog(
//                       context: context,
//                       builder: (_) => CreateFamilyGroupDialog(
//                         soldierId: user.userId,
//                         familyUIDs: familyMembers.map((m) => m.userId).toList(),
//                       ),
//                     );
//                     if (created == true) _load();
//                   },
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             if (groups.isEmpty)
//               const Text("No groups created yet.", style: TextStyle(color: Colors.white54))
//             else
//               ...groups.map((g) => FamilyGroupTile(group: g)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';
import '../../../models/family_group_model.dart';

import '../services/family_management_service.dart';
import '../services/user_service.dart';

import '../widgets/create_family_group_dialog.dart';
import '../widgets/family_group_tile.dart';
import '../widgets/family_member_card.dart';
import '../../../providers/user_provider.dart';

class SoldierHomeScreen extends StatefulWidget {
  const SoldierHomeScreen({super.key});

  @override
  State<SoldierHomeScreen> createState() => _SoldierHomeScreenState();
}

class _SoldierHomeScreenState extends State<SoldierHomeScreen> {
  List<UserModel> familyMembers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<UserProvider>();
    final user = provider.user;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    // 👉 Fetch only approved family members mapped to this soldier
    familyMembers = await UserService().getFamilyMembers(user.serviceNumber ?? "");

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final user = provider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Loading user...")));
    }

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${user.fullName}"),
        actions: [
          /// 🔔 Alerts Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("alerts")
                .where("receiverId", isEqualTo: user.userId)
                .where("status", isEqualTo: "unread")
                .snapshots(),
            builder: (_, snap) {
              final count = snap.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => Navigator.pushNamed(context, "/alerts"),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.red,
                        child: Text(
                          "$count",
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async => _loadInitialData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// 🟢 FAMILY MEMBERS SECTION
            Text("Family Members", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            if (familyMembers.isEmpty)
              const Text("No family members linked yet.",
                  style: TextStyle(color: Colors.white54))
            else
              ...familyMembers.map((m) => FamilyMemberCard(
                user: m,
                onApprove: () async {
                  await FamilyManagementService().approveMember(m.userId);
                  _loadInitialData();
                },
                onReject: () async {
                  await FamilyManagementService().rejectMember(m.userId);
                  _loadInitialData();
                },
              )),

            const SizedBox(height: 25),

            /// 🟡 FAMILY GROUPS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Family Groups", style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.yellowAccent),
                  onPressed: () async {
                    final created = await showDialog(
                      context: context,
                      builder: (_) => CreateFamilyGroupDialog(
                        soldierId: user.userId,
                        familyUIDs: familyMembers.map((m) => m.userId).toList(),
                      ),
                    );
                    if (created == true) {
                      setState(() {}); // refresh StreamBuilder
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// ⬇️ LIVE GROUPS FROM MAIN COLLECTION
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("groups")
                  .where("createdBy", isEqualTo: user.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No groups created yet.",
                      style: TextStyle(color: Colors.white54));
                }

                final List<FamilyGroupModel> groups = docs.map(
                      (d) => FamilyGroupModel.fromMap(
                    d.id,
                    d.data() as Map<String, dynamic>,
                  ),
                ).toList();

                return Column(
                  children: groups.map((g) => FamilyGroupTile(group: g)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
