enum CallType { voice }

enum CallStatus { ringing, ongoing, missed, ended }

class CallParticipant {
  final String uid;
  final String name;
  String status;

  CallParticipant({
    required this.uid,
    required this.name,
    this.status = "ringing",
  });

  Map<String, dynamic> toMap() => {
    "uid": uid,
    "name": name,
    "status": status,
  };
}
