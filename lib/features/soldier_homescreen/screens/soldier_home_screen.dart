//
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../../models/user_model.dart';
// import '../../../models/family_group_model.dart';
//
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
//   bool loading = true;
//   bool _initialized = false;
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//
//     if (!_initialized) {
//       _initialized = true;
//       _waitForUserAndLoad();
//     }
//   }
//
//   /// 🔥 Wait until provider loads user, then fetch family members
//   Future<void> _waitForUserAndLoad() async {
//     final provider = context.read<UserProvider>();
//
//     // ⏳ Wait until provider loads user
//     while (provider.user == null) {
//       await Future.delayed(const Duration(milliseconds: 150));
//     }
//
//     await _loadInitialData();
//   }
//
//   Future<void> _loadInitialData() async {
//     final user = context.read<UserProvider>().user;
//
//     if (user == null) {
//       setState(() => loading = false);
//       return;
//     }
//
//     // 👉 Fetch approved + non-approved members linked to soldier service number
//     familyMembers = await UserService().getFamilyMembers(user.serviceNumber ?? "");
//
//     setState(() => loading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<UserProvider>();
//     final user = provider.user;
//
//     if (user == null || loading) {
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
//               final count = snap.data?.docs.length ?? 0;
//
//               return Stack(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.notifications),
//                     onPressed: () => Navigator.pushNamed(context, "/alerts"),
//                   ),
//                   if (count > 0)
//                     Positioned(
//                       right: 6,
//                       top: 6,
//                       child: CircleAvatar(
//                         radius: 9,
//                         backgroundColor: Colors.red,
//                         child: Text("$count",
//                             style: const TextStyle(fontSize: 11, color: Colors.white)),
//                       ),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//
//       body: RefreshIndicator(
//         onRefresh: _loadInitialData,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//
//             Text("Family Members", style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 10),
//
//             if (familyMembers.isEmpty)
//               const Text("No family members linked yet.",
//                   style: TextStyle(color: Colors.white54))
//             else
//               ...familyMembers.map(
//                     (m) => FamilyMemberCard(
//                   user: m,
//                   onApprove: () async {
//                     await FamilyManagementService().approveMember(m.userId);
//                     _loadInitialData();
//                   },
//                   onReject: () async {
//                     await FamilyManagementService().rejectMember(m.userId);
//                     _loadInitialData();
//                   },
//                 ),
//               ),
//
//             const SizedBox(height: 25),
//
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
//                     if (created == true) setState(() {});
//                   },
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 10),
//
//             StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection("groups")
//                   .where("createdBy", isEqualTo: user.userId)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 final docs = snapshot.data!.docs;
//
//                 if (docs.isEmpty) {
//                   return const Text(
//                     "No groups created yet.",
//                     style: TextStyle(color: Colors.white54),
//                   );
//                 }
//
//                 final List<FamilyGroupModel> groups = docs.map(
//                       (d) => FamilyGroupModel.fromMap(d.id, d.data() as Map<String, dynamic>),
//                 ).toList();
//
//                 return Column(
//                   children: groups.map((g) => FamilyGroupTile(group: g)).toList(),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
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
import 'alert_screen.dart';

class SoldierHomeScreen extends StatefulWidget {
  const SoldierHomeScreen({super.key});

  @override
  State<SoldierHomeScreen> createState() => _SoldierHomeScreenState();
}

class _SoldierHomeScreenState extends State<SoldierHomeScreen> {
  List<UserModel> familyMembers = [];
  bool loading = true;
  bool _initialized = false;
  int alertPending = 0;
  int alertTotal = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _waitForUserAndLoad();
    }
  }

  Future<void> _waitForUserAndLoad() async {
    final provider = context.read<UserProvider>();

    while (provider.user == null) {
      await Future.delayed(const Duration(milliseconds: 150));
    }

    await _loadInitialData();
    _listenAlerts();
  }

  Future<void> _loadInitialData() async {
    final user = context.read<UserProvider>().user;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    familyMembers = await UserService().getFamilyMembers(user.serviceNumber ?? "");

    setState(() => loading = false);
  }

  /// 🔥 Listen live to alert changes
  void _listenAlerts() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection("alerts")
        .snapshots()
        .listen((snapshot) {
      final alerts = snapshot.docs;

      setState(() {
        alertTotal = alerts.length;
        alertPending = alerts.where((d) => d["status"] == "pending").length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final user = provider.user;

    if (user == null || loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${user.fullName}"),
      ),

      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            /// 🚨 ALERT SUMMARY CARD
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoldierAlertScreen()),
              ),
              child: Card(
                color: Colors.red.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, size: 32, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Alerts", style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            "$alertTotal Total • $alertPending Pending",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// 👨‍👩‍👧 FAMILY MEMBERS
            Text("Family Members", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            if (familyMembers.isEmpty)
              const Text("No family members linked yet.", style: TextStyle(color: Colors.white54))
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

            /// 👥 GROUPS
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
                    if (created == true) setState(() {});
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("groups")
                  .where("createdBy", isEqualTo: user.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Text("No groups created yet.", style: TextStyle(color: Colors.white54));
                }

                final List<FamilyGroupModel> groups = docs.map(
                      (d) => FamilyGroupModel.fromMap(d.id, d.data() as Map<String, dynamic>),
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
