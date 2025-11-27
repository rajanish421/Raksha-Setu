import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // -------------------------
  // Admin actions (adminLogs)
  // -------------------------
  /// Example action values: "approve_user", "reject_user", "suspend_user",
  /// "create_group", "edit_group", "delete_group", "assign_officer", "remove_member"
  static Future<void> logAdminAction({
    required String action,
    String? adminUid,
    String? adminName,
    String? targetUid,
    String? targetName,
    String? groupId,
    String? groupName,
    Map<String, dynamic>? meta, // optional additional structured data
  }) async {
    try {
      final uid = adminUid ?? _auth.currentUser?.uid;
      final adminDoc = adminName != null
          ? adminName
          : (uid != null ? await _fetchUserName(uid) : 'unknown');

      await _db.collection('adminLogs').add({
        'adminUid': uid ?? 'unknown',
        'adminName': adminDoc,
        'action': action,
        'targetUid': targetUid,
        'targetName': targetName,
        'groupId': groupId,
        'groupName': groupName,
        'meta': meta ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      // Optional: write to system logs on failure
      await logSystemEvent(level: 'ERROR', message: 'logAdminAction failed', info: {
        'error': e.toString(),
        'stack': st.toString(),
        'action': action,
      });
    }
  }

  // -------------------------
  // User actions (userLogs)
  // -------------------------
  /// Example actions: "register", "login", "logout", "failed_login", "password_change"
  static Future<void> logUserAction({
    required String action,
    String? uid,
    String? name,
    String? role,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final userId = uid ?? _auth.currentUser?.uid ?? 'unknown';
      final userName = name ?? (userId != 'unknown' ? await _fetchUserName(userId) : 'unknown');

      await _db.collection('userLogs').add({
        'uid': userId,
        'name': userName,
        'role': role ?? '',
        'action': action,
        'meta': meta ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      await logSystemEvent(level: 'ERROR', message: 'logUserAction failed', info: {
        'error': e.toString(),
        'stack': st.toString(),
        'action': action,
      });
    }
  }

  // -------------------------
  // Alert actions (alertLogs)
  // -------------------------
  /// Example actions: "acknowledged", "resolved", "created"
  static Future<void> logAlertAction({
    required String alertId,
    required String action,
    String? performedByUid,
    String? performedByName,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final uid = performedByUid ?? _auth.currentUser?.uid ?? 'system';
      final name = performedByName ?? (uid != 'system' ? await _fetchUserName(uid) : 'system');

      await _db.collection('alertLogs').add({
        'alertId': alertId,
        'action': action,
        'performedByUid': uid,
        'performedBy': name,
        'meta': meta ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      await logSystemEvent(level: 'ERROR', message: 'logAlertAction failed', info: {
        'error': e.toString(),
        'stack': st.toString(),
        'alertId': alertId,
      });
    }
  }

  // -------------------------
  // System events (systemLogs)
  // -------------------------
  /// level: "INFO" | "WARN" | "ERROR" | "CRITICAL"
  static Future<void> logSystemEvent({
    required String level,
    required String message,
    Map<String, dynamic>? info,
  }) async {
    try {
      await _db.collection('systemLogs').add({
        'level': level,
        'message': message,
        'info': info ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // If system logging fails, there's not much we can do.
      // Avoid recursion by not calling logSystemEvent here.
    }
  }

  // -------------------------
  // Helper: fetch user display name from users collection
  // -------------------------
  static Future<String> _fetchUserName(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return (data['fullName'] ?? data['name'] ?? 'Unknown').toString();
        }
      }
    } catch (_) {
      // ignore and fallback
    }
    return 'Unknown';
  }
}
