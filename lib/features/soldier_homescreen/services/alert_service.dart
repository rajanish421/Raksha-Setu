import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertService {

  final _alerts = FirebaseFirestore.instance.collection("alerts");

  Future<void> createAlert({
    required String groupId,
    required String groupName,
    required String type,
    required String title,
    required String message,
    dynamic location,
  }) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    await _alerts.add({
      "alertId": "",
      "groupId": groupId,
      "groupName": groupName,
      "type": type,
      "title": title,
      "message": message,
      "senderUid": user.uid,
      "senderName": userDoc["fullName"],
      "senderRole": userDoc["role"],
      "timestamp": FieldValue.serverTimestamp(),
      "location": location ?? null,
      "status": "pending",
    });
  }
}
