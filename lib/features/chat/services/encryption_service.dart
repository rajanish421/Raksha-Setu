import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  EncryptionService._internal();

  static final EncryptionService instance = EncryptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache per-group keys in memory
  final Map<String, encrypt.Key> _groupKeys = {};

  /// Ensure there is a symmetric AES key for this group.
  /// If not present in Firestore, generate & store one.
  Future<void> ensureGroupKey(String groupId) async {
    if (_groupKeys.containsKey(groupId)) return;

    final docRef = _firestore.collection('groups').doc(groupId);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null && doc.data()!['encKey'] != null) {
      final String b64 = doc.data()!['encKey'] as String;
      final keyBytes = base64Decode(b64);
      _groupKeys[groupId] = encrypt.Key(Uint8List.fromList(keyBytes));
      return;
    }

    // Generate new 32-byte AES key (256-bit)
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    final key = encrypt.Key(Uint8List.fromList(bytes));
    final encKeyB64 = base64Encode(bytes);

    await docRef.set(
      {
        'encKey': encKeyB64,
        'encKeyVersion': 1,
      },
      SetOptions(merge: true),
    );

    _groupKeys[groupId] = key;
  }

  /// Encrypt text for a group using AES-256-CBC.
  /// Returns a base64 string: base64( IV(16 bytes) + ciphertext )
  Future<String> encryptTextForGroup(String groupId, String plaintext) async {
    await ensureGroupKey(groupId);
    final key = _groupKeys[groupId]!;
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final combinedBytes = <int>[];
    combinedBytes.addAll(iv.bytes);
    combinedBytes.addAll(encrypted.bytes);

    return base64Encode(combinedBytes);
  }

  /// Decrypt text for a group.
  /// Expects base64( IV + ciphertext )
  String decryptTextForGroup(String groupId, String cipherBase64) {
    final key = _groupKeys[groupId];
    if (key == null) {
      return "[LOCKED]";
    }

    final allBytes = base64Decode(cipherBase64);
    if (allBytes.length <= 16) return "[INVALID]";

    final ivBytes = allBytes.sublist(0, 16);
    final cipherBytes = allBytes.sublist(16);

    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypt.Encrypted(Uint8List.fromList(cipherBytes));

    try {
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return "[DECRYPT FAILED]";
    }
  }
}
