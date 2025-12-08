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
    );
  }
}
