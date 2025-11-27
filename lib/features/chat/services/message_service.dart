









import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/message_model.dart';
import 'encryption_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/message_model.dart';
import 'encryption_service.dart';

class MessageService {
  MessageService._internal();
  static final MessageService instance = MessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _messagesCollection(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages');
  }

  /// ENCRYPTED send
  Future<void> sendTextMessage({
    required String groupId,
    required String text,
    required String senderName,
    required String senderRole,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 🔐 encrypt
    final encryptedText = await EncryptionService.instance
        .encryptTextForGroup(groupId, trimmed);

    final docRef = _messagesCollection(groupId).doc();

    final msg = MessageModel(
      messageId: docRef.id,
      groupId: groupId,
      senderId: user.uid,
      senderName: senderName,
      senderRole: senderRole,
      type: MessageType.text,
      content: encryptedText, // ciphertext
      fileUrl: null,
      isEncrypted: true,
      createdAt: DateTime.now().toUtc(),
      readBy: <String>[user.uid],
      deletedAt: null,

    );

    await docRef.set(msg.toMap());
  }

  /// DECRYPTED stream
  Stream<List<MessageModel>> streamGroupMessages(String groupId) async* {
    // ensure key loaded once
    await EncryptionService.instance.ensureGroupKey(groupId);

    await for (final snap in _messagesCollection(groupId)
        .orderBy('createdAt', descending: false)
        .snapshots()) {
      final List<MessageModel> list = [];

      for (final doc in snap.docs) {
        var m = MessageModel.fromDoc(doc);

        if (m.isEncrypted &&
            m.type == MessageType.text &&
            m.content != null &&
            m.content!.isNotEmpty) {
          final plain = EncryptionService.instance
              .decryptTextForGroup(groupId, m.content!);
          m = m.copyWith(content: plain);
        }

        list.add(m);
      }

      yield list;
    }
  }



  /// Mark as read
  Future<void> markMessageAsRead({
    required String groupId,
    required String messageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _messagesCollection(groupId).doc(messageId);

    await docRef.update({
      'readBy': FieldValue.arrayUnion([user.uid]),
    });
  }

  /// Mark for soft delete (retention)
  Future<void> softDeleteMessage({
    required String groupId,
    required String messageId,
  }) async {
    await _messagesCollection(groupId).doc(messageId).update({
      'deletedAt': DateTime.now().toUtc(),
    });
  }
}













// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../../../models/message_model.dart';
//
// class MessageService {
//   MessageService._internal();
//
//   static final MessageService instance = MessageService._internal();
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   /// Firestore path helper:
//   /// groups/{groupId}/messages
//   CollectionReference<Map<String, dynamic>> _messagesCollection(String groupId) {
//     return _firestore
//         .collection('groups')
//         .doc(groupId)
//         .collection('messages');
//   }
//
//   /// Send a secure text message to a group
//   Future<void> sendTextMessage({
//     required String groupId,
//     required String text,
//     required String senderName,
//     required String senderRole,
//   }) async {
//     final user = _auth.currentUser;
//     if (user == null) {
//       throw Exception("User not logged in");
//     }
//
//     final String trimmed = text.trim();
//     if (trimmed.isEmpty) return;
//
//     final docRef = _messagesCollection(groupId).doc(); // auto id
//
//     final msg = MessageModel(
//       messageId: docRef.id,
//       groupId: groupId,
//       senderId: user.uid,
//       senderName: senderName,
//       senderRole: senderRole,
//       type: MessageType.text,
//       content: trimmed,
//       fileUrl: null,
//       isEncrypted: true, // logical flag for SIH
//       createdAt: DateTime.now().toUtc(),
//       readBy: <String>[user.uid], // sender has "read"
//       deletedAt: null,
//     );
//
//     await docRef.set(msg.toMap());
//   }
//
//   /// Stream messages for a given group (ordered by time)
//   Stream<List<MessageModel>> streamGroupMessages(String groupId) {
//     return _messagesCollection(groupId)
//         .orderBy('createdAt', descending: false)
//         .snapshots()
//         .map((snap) {
//       return snap.docs
//           .map((doc) => MessageModel.fromDoc(doc))
//           .toList();
//     });
//   }
//
//   /// Mark a message as read by current user
//   Future<void> markMessageAsRead({
//     required String groupId,
//     required String messageId,
//   }) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     final docRef = _messagesCollection(groupId).doc(messageId);
//
//     await docRef.update({
//       'readBy': FieldValue.arrayUnion([user.uid]),
//     });
//   }
//
//   /// (Optional for later) Soft delete for retention
//   Future<void> softDeleteMessage({
//     required String groupId,
//     required String messageId,
//   }) async {
//     await _messagesCollection(groupId).doc(messageId).update({
//       'deletedAt': DateTime.now().toUtc(),
//     });
//   }
// }
