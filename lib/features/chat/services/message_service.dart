
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/message_model.dart';
import '../services/encryption_service.dart';

class MessageService {
  MessageService._internal();
  static final MessageService instance = MessageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firestore location: groups → groupId → messages
  CollectionReference<Map<String, dynamic>> _messages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages');
  }

  // ---------------------------------------------------------
  // 📝 SEND TEXT MESSAGE (Encrypted)
  // ---------------------------------------------------------
  Future<void> sendTextMessage({
    required String groupId,
    required String text,
    required String senderName,
    required String senderRole,
    String? replyTo,
    String? replyPreview,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Encrypt message before sending (SIH requirement)
    final encrypted = await EncryptionService.instance.encryptTextForGroup(
      groupId,
      trimmed,
    );

    final docRef = _messages(groupId).doc();

    final msg = MessageModel(
      id: docRef.id,
      groupId: groupId,
      senderId: user.uid,
      senderName: senderName,
      senderRole: senderRole,

      type: MessageType.text,
      text: encrypted,

      fileUrl: null,
      fileName: null,
      fileSize: null,
      thumbUrl: null,

      replyToMessageId: replyTo,
      replySnippet: replyPreview,

      isEncrypted: true,
      restrictShare: true,

      deliveredTo: [user.uid],
      seenBy: [user.uid],

      createdAt: DateTime.now().toUtc(),
      deletedAt: null,
    );

    await docRef.set(msg.toMap());
  }

  // ---------------------------------------------------------
  // 🖼 SEND IMAGE MESSAGE (Cloudinary)
  // ---------------------------------------------------------
  Future<void> sendImageMessage({
    required String groupId,
    required String imageUrl,
    required String senderName,
    required String senderRole,
    String? fileName,
    int? fileSize,
    String? replyTo,
    String? replyPreview,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final docRef = _messages(groupId).doc();

    final msg = MessageModel(
      id: docRef.id,
      groupId: groupId,
      senderId: user.uid,
      senderName: senderName,
      senderRole: senderRole,

      type: MessageType.image,
      text: null,

      fileUrl: imageUrl,
      fileName: fileName,
      fileSize: fileSize,

      thumbUrl: null,
      replyToMessageId: replyTo,
      replySnippet: replyPreview,

      isEncrypted: false,
      restrictShare: true,

      deliveredTo: [user.uid],
      seenBy: [user.uid],

      createdAt: DateTime.now().toUtc(),
      deletedAt: null,
    );

    await docRef.set(msg.toMap());
  }

  // ---------------------------------------------------------
  // 📄 SEND DOCUMENT MESSAGE (PDF)
  // ---------------------------------------------------------
  Future<void> sendDocumentMessage({
    required String groupId,
    required String docUrl,
    required String senderName,
    required String senderRole,
    required String fileName,
    required int fileSize,
    String? replyTo,
    String? replyPreview,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final docRef = _messages(groupId).doc();

    final msg = MessageModel(
      id: docRef.id,
      groupId: groupId,
      senderId: user.uid,
      senderName: senderName,
      senderRole: senderRole,

      type: MessageType.document,
      text: null,

      fileUrl: docUrl,
      fileName: fileName,
      fileSize: fileSize,

      thumbUrl: null,
      replyToMessageId: replyTo,
      replySnippet: replyPreview,

      isEncrypted: false,
      restrictShare: true,

      deliveredTo: [user.uid],
      seenBy: [user.uid],

      createdAt: DateTime.now().toUtc(),
      deletedAt: null,
    );

    await docRef.set(msg.toMap());
  }

  // ---------------------------------------------------------
  // 🎤 SEND VOICE MESSAGE
  // ---------------------------------------------------------
  Future<void> sendVoiceMessage({
    required String groupId,
    required String fileUrl,
    required String senderName,
    required String senderRole,
    int? duration,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _messages(groupId).doc();

    final msg = MessageModel(
      id: docRef.id,
      groupId: groupId,
      senderId: user.uid,
      senderName: senderName,
      senderRole: senderRole,

      type: MessageType.voice,
      text: null,

      fileUrl: fileUrl,
      fileName: "voice_${DateTime.now().millisecondsSinceEpoch}.m4a",
      fileSize: null,
      thumbUrl: null,

      replyToMessageId: null,
      replySnippet: null,

      isEncrypted: false,
      restrictShare: true,

      deliveredTo: [user.uid],
      seenBy: [user.uid],

      createdAt: DateTime.now().toUtc(),
      deletedAt: null,
    );

    await docRef.set(msg.toMap());
  }

  // ---------------------------------------------------------
  // 🔄 REAL-TIME STREAM + DECRYPT TEXT
  // ---------------------------------------------------------
  Stream<List<MessageModel>> streamMessages(String groupId) async* {
    await EncryptionService.instance.ensureGroupKey(groupId);

    await for (final snap in _messages(groupId)
        .orderBy('createdAt', descending: false)
        .snapshots()) {
      final List<MessageModel> parsed = [];

      for (final doc in snap.docs) {
        MessageModel msg = MessageModel.fromDoc(doc);

        /// Decrypt only encrypted text messages
        if (msg.type == MessageType.text &&
            msg.isEncrypted &&
            msg.text != null &&
            _isValidBase64(msg.text!)) {
          try {
            final decrypted = EncryptionService.instance.decryptTextForGroup(
              groupId,
              msg.text!,
            );
            msg = msg.copyWith(text: decrypted);
          } catch (_) {
            msg = msg.copyWith(text: "[Decryption Failed]");
          }
        }

        parsed.add(msg);
      }

      yield parsed;
    }
  }

  bool _isValidBase64(String input) {
    try {
      base64Decode(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------
  // 📌 MESSAGE DELIVERY + READ RECEIPTS
  // ---------------------------------------------------------
  Future<void> markDelivered(String groupId, String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _messages(groupId).doc(messageId).update({
      "deliveredTo": FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> markSeen(String groupId, String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _messages(groupId).doc(messageId).update({
      "seenBy": FieldValue.arrayUnion([uid]),
    });
  }

  // ---------------------------------------------------------
  // 🗑 SOFT DELETE (Retention Policy)
  // ---------------------------------------------------------
  Future<void> softDelete(String groupId, String messageId) async {
    await _messages(groupId).doc(messageId).update({
      "deletedAt": DateTime.now().toUtc(),
    });
  }
}








// class MessageService {
//   MessageService._internal();
//   static final MessageService instance = MessageService._internal();
//
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   CollectionReference<Map<String, dynamic>> _messages(String groupId) {
//     return _firestore
//         .collection('groups')
//         .doc(groupId)
//         .collection('messages');
//   }
//
//   // ---------------------------------------------------------
//   // SEND TEXT MESSAGE (encrypted)
//   // ---------------------------------------------------------
//   Future<void> sendTextMessage({
//     required String groupId,
//     required String text,
//     required String senderName,
//     required String senderRole,
//     String? replyTo,      // optional for future threaded replies
//     String? replyPreview, // snippet
//   }) async {
//     final user = _auth.currentUser;
//     if (user == null) throw Exception("User not logged in");
//
//     final trimmed = text.trim();
//     if (trimmed.isEmpty) return;
//
//     // encrypt
//     final encrypted = await EncryptionService.instance.encryptTextForGroup(
//       groupId,
//       trimmed,
//     );
//
//     final docRef = _messages(groupId).doc();
//
//     final msg = MessageModel(
//       id: docRef.id,
//       groupId: groupId,
//       senderId: user.uid,
//       senderName: senderName,
//       senderRole: senderRole,
//
//       type: MessageType.text,
//       text: encrypted,
//
//       fileUrl: null,
//       fileName: null,
//       fileSize: null,
//       thumbUrl: null,
//
//       replyToMessageId: replyTo,
//       replySnippet: replyPreview,
//
//       isEncrypted: true,
//       restrictShare: true,
//
//       deliveredTo: [user.uid],
//       seenBy: [user.uid],
//
//       createdAt: DateTime.now().toUtc(),
//       deletedAt: null,
//     );
//
//     await docRef.set(msg.toMap());
//   }
//
//   // ---------------------------------------------------------
//   // REAL-TIME STREAM WITH DECRYPTION
//   // ---------------------------------------------------------
//
//   bool _isValidBase64(String input) {
//     try {
//       base64Decode(input);
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   Stream<List<MessageModel>> streamMessages(String groupId) async* {
//     await EncryptionService.instance.ensureGroupKey(groupId);
//
//     await for (final snap in _messages(groupId)
//         .orderBy('createdAt', descending: false)
//         .snapshots()) {
//
//       final List<MessageModel> result = [];
//
//       for (final doc in snap.docs) {
//         MessageModel msg = MessageModel.fromDoc(doc);
//
//         // decrypt only text messages
//         if (msg.type == MessageType.text && msg.isEncrypted && msg.text != null) {
//           if (_isValidBase64(msg.text!)) {
//             try {
//               final plain = EncryptionService.instance.decryptTextForGroup(
//                 groupId,
//                 msg.text!,
//               );
//               msg = msg.copyWith(text: plain);
//             } catch (_) {
//               msg = msg.copyWith(text: "[Decrypt failed]");
//             }
//           } else {
//             msg = msg.copyWith(text: msg.text);
//           }
//         }
//
//         result.add(msg);
//       }
//
//       yield result;
//     }
//   }
//
//   // ---------------------------------------------------------
//   // MARK AS DELIVERED (WhatsApp style ✓✓ gray)
//   // ---------------------------------------------------------
//   Future<void> markDelivered(String groupId, String messageId) async {
//     final uid = _auth.currentUser?.uid;
//     if (uid == null) return;
//
//     final doc = _messages(groupId).doc(messageId);
//     await doc.update({
//       "deliveredTo": FieldValue.arrayUnion([uid]),
//     });
//   }
//
//   // ---------------------------------------------------------
//   // MARK AS SEEN (blue ticks)
//   // ---------------------------------------------------------
//   Future<void> markSeen(String groupId, String messageId) async {
//     final uid = _auth.currentUser?.uid;
//     if (uid == null) return;
//
//     final doc = _messages(groupId).doc(messageId);
//     await doc.update({
//       "seenBy": FieldValue.arrayUnion([uid]),
//     });
//   }
//
//   // ---------------------------------------------------------
//   // SOFT DELETE (retention policy)
//   // ---------------------------------------------------------
//   Future<void> softDelete(String groupId, String messageId) async {
//     await _messages(groupId).doc(messageId).update({
//       "deletedAt": DateTime.now().toUtc(),
//     });
//   }
// }
