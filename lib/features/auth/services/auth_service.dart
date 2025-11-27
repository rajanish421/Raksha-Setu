import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../log_service.dart';
import '../../../models/user_model.dart';


class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collection name
  static const String _usersCollection = 'users';

  /// Helper: build internal email based on role & identifiers
  /// Soldiers/Veterans → serviceNumber@defence.app
  /// Family → phone@defence.app
  String _buildInternalEmail({
    required String role,
    required String serviceNumber,
    required String phone,
  }) {
    if (role == 'family') {
      return '${phone.trim()}@defence.app';
    }
    return '${serviceNumber.trim()}@defence.app';
  }

  /// Register a new user:
  /// 1. Create Firebase Auth account
  /// 2. Create Firestore user document with status=pending
  Future<UserModel> registerUser({
    required String fullName,
    required String phone,
    required String role, // 'soldier' | 'family' | 'veteran'
    String? serviceNumber,
    String? referenceServiceNumber,
    String? relationship,
    String? rank,
    String? unit,
    required String password,
    required String selfieUrl,
    required String documentUrl,
  }) async {
    try {
      // Basic validation based on role
      if (role == 'family') {
        if (referenceServiceNumber == null || referenceServiceNumber.isEmpty) {
          throw Exception('Reference service number is required for family.');
        }
      } else {
        if (serviceNumber == null || serviceNumber.isEmpty) {
          throw Exception('Service number is required for soldiers/veterans.');
        }
      }

      final String email = _buildInternalEmail(
        role: role,
        serviceNumber: serviceNumber ?? '',
        phone: phone,
      );

      // 1. Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // 2. Build UserModel
      final userModel = UserModel(
        userId: uid,
        fullName: fullName.trim(),
        phone: phone.trim(),
        role: role,
        status: 'pending', // VERY IMPORTANT: HQ must approve
        serviceNumber: role == 'family' ? null : serviceNumber?.trim(),
        rank: rank?.trim(),
        unit: unit?.trim(),
        referenceServiceNumber:
        role == 'family' ? referenceServiceNumber?.trim() : null,
        relationship: role == 'family' ? relationship?.trim() : null,
        selfieUrl: selfieUrl,
        documentUrl: documentUrl,
        createdAt: DateTime.now().toUtc(),
        approvedAt: null,
      );

      // 3. Save to Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .set(userModel.toMap());


      // log added
      await LogService.logUserAction(
        action: 'register',
        uid: uid,
        name: fullName,
        role: role,
      );


      return userModel;
    } on FirebaseAuthException catch (e) {
      // Convert FirebaseAuthException to user-friendly messages
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this ID/phone.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  /// Step 1 of Login:
  /// - User enters ServiceNumber OR Phone (for family) + Password
  /// - We:
  ///   1. Look up user in Firestore by serviceNumber or phone
  ///   2. Build internal email
  ///   3. Sign in with Firebase Auth using email+password
  ///   4. Return UserModel (including status)
  Future<UserModel> loginWithIdentifierAndPassword({
    required String identifier, // serviceNumber OR phone
    required String password,
  }) async {
    try {
      // 1. Find user in Firestore
      final _UserLookupResult lookupResult =
      await _findUserByIdentifier(identifier);

      final String email = _buildInternalEmail(
        role: lookupResult.role,
        serviceNumber: lookupResult.serviceNumber ?? '',
        phone: lookupResult.phone,
      );

      // 2. Sign in through Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Fetch user document
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(lookupResult.userId)
          .get();

      if (!doc.exists) {
        throw Exception('User profile not found.');
      }

      final data = doc.data()!;
      final userModel = UserModel.fromMap(data);

      // Log successful login
      await LogService.logUserAction(
        action: 'login',
        uid: userModel.userId,
        name: userModel.fullName,
        role: userModel.role,
      );


      return userModel;
    } on FirebaseAuthException catch (e) {

      await LogService.logUserAction(
        action: 'failed_login',
        meta: {'identifier': identifier, 'reason': e.code},
      );

      String message = 'Login failed';
      if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'user-not-found') {
        message = 'No account found for this ID/phone.';
      }
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  /// Find user by:
  /// 1. serviceNumber == identifier
  /// 2. if not found → phone == identifier
  Future<_UserLookupResult> _findUserByIdentifier(String identifier) async {
    final String trimmed = identifier.trim();

    // Try serviceNumber
    final byService = await _firestore
        .collection(_usersCollection)
        .where('serviceNumber', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (byService.docs.isNotEmpty) {
      final doc = byService.docs.first;
      final data = doc.data();
      return _UserLookupResult(
        userId: data['userId'],
        role: data['role'],
        phone: data['phone'],
        serviceNumber: data['serviceNumber'],
      );
    }

    // Try phone (family, or fallback)
    final byPhone = await _firestore
        .collection(_usersCollection)
        .where('phone', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (byPhone.docs.isNotEmpty) {
      final doc = byPhone.docs.first;
      final data = doc.data();
      return _UserLookupResult(
        userId: data['userId'],
        role: data['role'],
        phone: data['phone'],
        serviceNumber: data['serviceNumber'],
      );
    }

    throw Exception('No user found for this ID/phone.');
  }

  /// Get currently logged-in user's profile (if any)
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
    await _firestore.collection(_usersCollection).doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await LogService.logUserAction(action: 'logout');
    } catch (_) {}

    await _auth.signOut();
  }

}

/// Internal helper for lookup
class _UserLookupResult {
  final String userId;
  final String role;
  final String phone;
  final String? serviceNumber;

  _UserLookupResult({
    required this.userId,
    required this.role,
    required this.phone,
    required this.serviceNumber,
  });
}
