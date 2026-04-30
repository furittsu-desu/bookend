import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'encryption_service.dart';
import 'time_service.dart';

class StorageService {
  static const _firstLaunchKey = 'is_first_launch';

  late final SharedPreferences _prefs;
  final EncryptionService _encryptionService = EncryptionService();
  final TimeService _timeService = TimeService();

  String? _cachedKey;

  SharedPreferences get prefs => _prefs;
  TimeService get timeService => _timeService;

  Future<String> _getEncryptionKey() async {
    _cachedKey ??= await _encryptionService.getOrGenerateKey();
    return _cachedKey!;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  // ── Backup & Restore ────────────────────────────────────────────────

  Future<String> exportData() async {
    final Map<String, dynamic> allData = {};
    for (final key in _prefs.getKeys()) {
      allData[key] = _prefs.get(key);
    }
    final jsonString = jsonEncode(allData);

    final keyString = await _getEncryptionKey();
    final encryptionKey = encrypt.Key.fromUtf8(keyString);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(encryptionKey));

    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combined.setRange(0, iv.bytes.length, iv.bytes);
    combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);

    return base64Encode(combined);
  }

  Future<bool> importData(String base64String) async {
    try {
      final combined = base64Decode(base64String);

      final ivBytes = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);

      final keyString = await _getEncryptionKey();
      final encryptionKey = encrypt.Key.fromUtf8(keyString);
      final iv = encrypt.IV(ivBytes);
      final encrypter = encrypt.Encrypter(encrypt.AES(encryptionKey));

      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(encryptedBytes),
        iv: iv,
      );

      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      await _prefs.clear();

      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is String) {
          await _prefs.setString(entry.key, value);
        } else if (value is int) {
          await _prefs.setInt(entry.key, value);
        } else if (value is double) {
          await _prefs.setDouble(entry.key, value);
        } else if (value is bool) {
          await _prefs.setBool(entry.key, value);
        } else if (value is List) {
          final list = value.map((e) => e.toString()).toList();
          await _prefs.setStringList(entry.key, list);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
