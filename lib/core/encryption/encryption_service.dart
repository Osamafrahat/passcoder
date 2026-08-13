import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static const String _keyName = 'master_encryption_key';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Key> getEncryptionKey() async {
    String? existingKey = await _secureStorage.read(key: _keyName);

    if (existingKey != null) {
      return Key.fromBase64(existingKey);
    }

    final random = Random.secure();
    final keyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = random.nextInt(256);
    }

    final newKey = Key(keyBytes);
    await _secureStorage.write(key: _keyName, value: newKey.base64);
    return newKey;
  }

  Future<String> encryptData(String plainText) async {
    final key = await getEncryptionKey();
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final combined = utf8.encode(iv.base64) + utf8.encode(':') + utf8.encode(encrypted.base64);
    return base64.encode(combined);
  }

  Future<String> decryptData(String encryptedText) async {
    final key = await getEncryptionKey();
    final combined = base64.decode(encryptedText);
    final combinedStr = utf8.decode(combined);
    final parts = combinedStr.split(':');

    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> deleteEncryptionKey() async {
    await _secureStorage.delete(key: _keyName);
  }
}
