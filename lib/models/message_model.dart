import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, document, voice, system }

MessageType messageTypeFrom(String? value) {
  switch (value) {
    case 'image':
      return MessageType.image;
    case 'document':
      return MessageType.document;
    case 'voice':
      return MessageType.voice;
    case 'system':
      return MessageType.system;
    default:
      return MessageType.text;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.image:
      return 'image';
    case MessageType.document:
      return 'document';
    case MessageType.voice:
      return 'voice';
    case MessageType.system:
      return 'system';
    default:
      return 'text';
  }
}

class MessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderRole;

  final MessageType type;
  final String? text;

  // Attachments
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbUrl; // Image thumbnail later if needed

  // Reply threading
  final String? replyToMessageId;
  final String? replySnippet; // small preview in bubble

  // Encryption & Security
  final bool isEncrypted;
  final bool restrictShare; // no export, no forward

  // Delivery & Read
  final List<String> deliveredTo;
  final List<String> seenBy;

  // Time
  final DateTime createdAt;
  final DateTime? deletedAt;

  MessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.type,
    required this.text,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.thumbUrl,
    required this.replyToMessageId,
    required this.replySnippet,
    required this.isEncrypted,
    required this.restrictShare,
    required this.deliveredTo,
    required this.seenBy,
    required this.createdAt,
    required this.deletedAt,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',

      type: messageTypeFrom(data['type']),

      text: data['text'],

      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      thumbUrl: data['thumbUrl'],

      replyToMessageId: data['replyToMessageId'],
      replySnippet: data['replySnippet'],

      isEncrypted: data['isEncrypted'] ?? true,
      restrictShare: data['restrictShare'] ?? true,

      deliveredTo: List<String>.from(data['deliveredTo'] ?? []),
      seenBy: List<String>.from(data['seenBy'] ?? []),

      createdAt: _parse(data['createdAt']),
      deletedAt: data['deletedAt'] != null ? _parse(data['deletedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "groupId": groupId,
      "senderId": senderId,
      "senderName": senderName,
      "senderRole": senderRole,

      "type": messageTypeToString(type),
      "text": text,

      "fileUrl": fileUrl,
      "fileName": fileName,
      "fileSize": fileSize,
      "thumbUrl": thumbUrl,

      "replyToMessageId": replyToMessageId,
      "replySnippet": replySnippet,

      "isEncrypted": isEncrypted,
      "restrictShare": restrictShare,

      "deliveredTo": deliveredTo,
      "seenBy": seenBy,

      "createdAt": Timestamp.fromDate(createdAt),
      "deletedAt": deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  static DateTime _parse(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  MessageModel copyWith({
    String? text,
    List<String>? deliveredTo,
    List<String>? seenBy,
  }) {
    return MessageModel(
      id: id,
      groupId: groupId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      type: type,
      text: text ?? this.text,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      thumbUrl: thumbUrl,
      replyToMessageId: replyToMessageId,
      replySnippet: replySnippet,
      isEncrypted: isEncrypted,
      restrictShare: restrictShare,
      deliveredTo: deliveredTo ?? this.deliveredTo,
      seenBy: seenBy ?? this.seenBy,
      createdAt: createdAt,
      deletedAt: deletedAt,
    );
  }
}
