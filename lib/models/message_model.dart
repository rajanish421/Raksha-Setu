import 'package:cloud_firestore/cloud_firestore.dart';


enum MessageType {
  text,
  image,
  file,
  voice,
  system, // announcements / pinned / alerts
}

MessageType messageTypeFromString(String value) {
  switch (value) {
    case 'image':
      return MessageType.image;
    case 'file':
      return MessageType.file;
    case 'voice':
      return MessageType.voice;
    case 'system':
      return MessageType.system;
    case 'text':
    default:
      return MessageType.text;
  }
}

String messageTypeToString(MessageType type) {
  switch (type) {
    case MessageType.image:
      return 'image';
    case MessageType.file:
      return 'file';
    case MessageType.voice:
      return 'voice';
    case MessageType.system:
      return 'system';
    case MessageType.text:
    default:
      return 'text';
  }
}

class MessageModel {
  final String messageId;
  final String groupId;
  final String senderId;
  final String senderName;
  final String senderRole; // soldier / officer / family / admin (for system)
  final MessageType type;
  final String? content; // text content
  final String? fileUrl; // image/pdf/voice url (later Firebase Storage)
  final bool isEncrypted; // for SIH pitch (logical flag)
  final DateTime createdAt;
  final List<String> readBy; // userIds who read
  final DateTime? deletedAt; // for retention policies

  MessageModel({
    required this.messageId,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.type,
    required this.content,
    required this.fileUrl,
    required this.isEncrypted,
    required this.createdAt,
    required this.readBy,
    required this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'type': messageTypeToString(type),
      'content': content,
      'fileUrl': fileUrl,
      'isEncrypted': isEncrypted,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    };
  }

  factory MessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      messageId: data['messageId'] ?? doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      type: messageTypeFromString(data['type'] ?? 'text'),
      content: data['content'],
      fileUrl: data['fileUrl'],
      isEncrypted: data['isEncrypted'] ?? false,
      createdAt: _parseDate(data['createdAt']),
      readBy: List<String>.from(data['readBy'] ?? const <String>[]),
      deletedAt: data['deletedAt'] != null ? _parseDate(data['deletedAt']) : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now().toUtc();
  }

  MessageModel copyWith({
    String? messageId,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderRole,
    MessageType? type,
    String? content,
    String? fileUrl,
    bool? isEncrypted,
    DateTime? createdAt,
    List<String>? readBy,
    DateTime? deletedAt,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      type: type ?? this.type,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
