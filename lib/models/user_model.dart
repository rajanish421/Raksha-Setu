class UserModel {
  final String userId;
  final String fullName;
  final String phone;
  final String role;               // soldier | family | veteran | admin | superAdmin
  final String status;             // pending | approved | rejected | suspended

  // Soldier / Veteran
  final String? serviceNumber;
  final String? rank;
  final String? unit;

  // Family
  final String? referenceServiceNumber;
  final String? relationship;

  // Uploads
  final String selfieUrl;
  final String documentUrl;

  // Timestamps
  final DateTime createdAt;
  final DateTime? approvedAt;

  // 🟢 NEW FIELDS
  final bool isActive;
  final DateTime? lastSeen;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
    this.serviceNumber,
    this.rank,
    this.unit,
    this.referenceServiceNumber,
    this.relationship,
    required this.selfieUrl,
    required this.documentUrl,
    required this.createdAt,
    this.approvedAt,

    // NEW
    required this.isActive,
    this.lastSeen,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'role': role,
      'status': status,
      'serviceNumber': serviceNumber,
      'rank': rank,
      'unit': unit,
      'referenceServiceNumber': referenceServiceNumber,
      'relationship': relationship,
      'selfieUrl': selfieUrl,
      'documentUrl': documentUrl,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),

      // NEW
      'isActive': isActive,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  /// Create model from Firestore JSON
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'],
      fullName: map['fullName'],
      phone: map['phone'],
      role: map['role'],
      status: map['status'],
      serviceNumber: map['serviceNumber'],
      rank: map['rank'],
      unit: map['unit'],
      referenceServiceNumber: map['referenceServiceNumber'],
      relationship: map['relationship'],
      selfieUrl: map['selfieUrl'],
      documentUrl: map['documentUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      approvedAt: map['approvedAt'] != null
          ? DateTime.parse(map['approvedAt'])
          : null,

      // NEW
      isActive: map['isActive'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'])
          : null,
    );
  }
}
