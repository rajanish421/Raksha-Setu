import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  UserModel? get user => _user;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to user data live
  Future<void> loadUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    // Prevent duplicate listeners
    await _subscription?.cancel();

    _subscription = _firestore
        .collection("users")
        .doc(authUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      _user = UserModel.fromMap(data);
      notifyListeners();
    });
  }

  /// Called during logout
  Future<void> clear() async {
    await _subscription?.cancel();
    _subscription = null;
    _user = null;
    notifyListeners();
  }

  /// Optional manual refresh
  Future<void> refresh() async => loadUser();
}
