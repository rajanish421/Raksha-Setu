// class CallLogEntry {
//   final String id;
//   final String callerId;
//   final String callerName;
//   final String receiverId;
//   final String receiverName;
//   final String groupId;
//   final bool isGroup;
//   final bool isVideo;
//   final bool isMissed;
//   final int duration;
//   final DateTime timestamp;
//
//   CallLogEntry({
//     required this.id,
//     required this.callerId,
//     required this.callerName,
//     required this.receiverId,
//     required this.receiverName,
//     required this.groupId,
//     required this.isGroup,
//     required this.isVideo,
//     required this.isMissed,
//     required this.duration,
//     required this.timestamp,
//   });
//
//   factory CallLogEntry.fromMap(String id, Map<String, dynamic> map) {
//     return CallLogEntry(
//       id: id,
//       callerId: map["callerId"],
//       callerName: map["callerName"],
//       receiverId: map["receiverId"],
//       receiverName: map["receiverName"],
//       groupId: map["groupId"],
//       isGroup: map["isGroup"],
//       isVideo: map["isVideo"],
//       isMissed: map["isMissed"],
//       duration: map["duration"] ?? 0,
//       timestamp: (map["timestamp"]).toDate(),
//     );
//   }
// }
