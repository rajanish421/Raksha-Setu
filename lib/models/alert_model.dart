class AlertModel {
  final String alertId;
  final String groupId;
  final String groupName;
  final String type;
  final String title;
  final String message;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String status;
  final dynamic location;
  final dynamic timestamp;

  /// 👇 NEW FIELD
  final List<String> readBy;

  AlertModel({
    required this.alertId,
    required this.groupId,
    required this.groupName,
    required this.type,
    required this.title,
    required this.message,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.status,
    this.location,
    this.timestamp,

    /// 👇 Default Empty List
    this.readBy = const [],
  });

  factory AlertModel.fromMap(String id, Map<String, dynamic> json) {
    return AlertModel(
      alertId: id,
      groupId: json["groupId"] ?? "",
      groupName: json["groupName"] ?? "",
      type: json["type"] ?? "",
      title: json["title"] ?? "",
      message: json["message"] ?? "",
      senderUid: json["senderUid"] ?? "",
      senderName: json["senderName"] ?? "",
      senderRole: json["senderRole"] ?? "",
      status: json["status"] ?? "pending",
      location: json["location"],
      timestamp: json["timestamp"],

      /// 👇 Read list if exists, else empty
      readBy: List<String>.from(json["readBy"] ?? []),
    );
  }

  /// 👇 To save back to Firestore (optional use)
  Map<String, dynamic> toMap() {
    return {
      "groupId": groupId,
      "groupName": groupName,
      "type": type,
      "title": title,
      "message": message,
      "senderUid": senderUid,
      "senderName": senderName,
      "senderRole": senderRole,
      "status": status,
      "location": location,
      "timestamp": timestamp,
      "readBy": readBy,
    };
  }
}
