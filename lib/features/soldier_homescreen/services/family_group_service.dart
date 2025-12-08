// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import '../../../models/family_group_model.dart';
//
// class FamilyGroupService {
//   final ref = FirebaseFirestore.instance.collection("family_groups");
//
//
//
//   Future<void> createGroup(String name, List<String> members, String soldierId) async {
//     await ref.add({
//       "name": name,
//       "createdBy": soldierId,
//       "members": members,
//       "createdAt": DateTime.now().toIso8601String(),
//     });
//   }
//
//
//   Future<List<FamilyGroupModel>> getGroups(String soldierId) async {
//     final snapshot = await ref.where("createdBy", isEqualTo: soldierId).get();
//
//     return snapshot.docs
//         .map((d) => FamilyGroupModel.fromMap(d.id, d.data()))
//         .toList();
//   }
// }
