import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyManagementService {
  final usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> approveMember(String uid) async {
    await usersRef.doc(uid).update({
      "status": "approved",
      "approvedAt": DateTime.now().toIso8601String()
    });
  }

  Future<void> rejectMember(String uid) async {
    await usersRef.doc(uid).update({
      "status": "rejected",
    });
  }
}
