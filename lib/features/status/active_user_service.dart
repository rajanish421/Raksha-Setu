import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class ActiveUserService with WidgetsBindingObserver {
  static final ActiveUserService instance = ActiveUserService._internal();
  ActiveUserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Call this inside main init
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    _updateStatus(true); // when app starts assume user active
  }

  /// Called automatically when app state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_auth.currentUser == null) return; // no user logged in

    if (state == AppLifecycleState.resumed) {
      // App is in foreground
      _updateStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      // App minimized / closed
      _updateStatus(false);
    }
  }

  /// Update Firestore isActive field
  Future<void> _updateStatus(bool active) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).update({
        "isActive": active,
        "lastSeen": DateTime.now().toUtc(),
      });
    } catch (e) {
      print("⚠️ Failed to update active status: $e");
    }
  }

  /// Call on logout
  Future<void> markOffline() async {
    await _updateStatus(false);
  }
}
