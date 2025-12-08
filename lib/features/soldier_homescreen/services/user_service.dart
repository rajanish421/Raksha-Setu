import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/user_model.dart';

class UserService {
  final usersRef = FirebaseFirestore.instance.collection('users');

  Future<List<UserModel>> getFamilyMembers(String serviceNumber) async {
    final snapshot = await usersRef
        .where("role", isEqualTo: "family")
        .where("referenceServiceNumber", isEqualTo: serviceNumber)
        .get();

    return snapshot.docs.map((e) => UserModel.fromMap(e.data())).toList();
  }
}
