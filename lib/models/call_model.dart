class CallModel {
  final String callId;
  final String groupId;
  final List<String> participants;
  final String startedBy;
  final String type;
  final bool isActive;
  final DateTime createdAt;

  CallModel({
    required this.callId,
    required this.groupId,
    required this.participants,
    required this.startedBy,
    required this.type,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    "callId": callId,
    "groupId": groupId,
    "participants": participants,
    "startedBy": startedBy,
    "type": type,
    "isActive": isActive,
    "createdAt": createdAt.toUtc(),
  };

  static CallModel fromDoc(doc) => CallModel(
    callId: doc["callId"],
    groupId: doc["groupId"],
    participants: List<String>.from(doc["participants"]),
    startedBy: doc["startedBy"],
    type: doc["type"],
    isActive: doc["isActive"],
    createdAt: doc["createdAt"].toDate(),
  );
}
