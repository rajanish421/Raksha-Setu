import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  final _firestore = FirebaseFirestore.instance;

  Future<void> loadUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    final doc = await _firestore.collection("users").doc(authUser.uid).get();
    if (!doc.exists) return;

    _user = UserModel.fromMap(doc.data()!);
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
