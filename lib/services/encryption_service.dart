import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final FlutterSecureStorage _storage;

  EncryptionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyName = 'aes_encryption_key';

  Future<String> getOrGenerateKey() async {
    String? key = await _storage.read(key: _keyName);
    if (key == null) {
      key = _generateRandomKey();
      await _storage.write(key: _keyName, value: key);
    }
    return key;
  }

  String _generateRandomKey() {
    final random = Random.secure();
    final values = List<int>.generate(24, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
}
