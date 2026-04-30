import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/routine_task.dart';
import 'storage_service.dart';

class HiveStorageService implements BaseStorage {
  static const _metaBoxName = 'meta';
  static const _routinesBoxName = 'routines';
  static const _activityBoxName = 'activity';
  static const _journalBoxName = 'journal';
  static const _secureKeyName = 'hive_encryption_key';

  late final Box _metaBox;
  late final Box _routinesBox;
  late final Box _activityBox;
  late final Box _journalBox;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RoutineTaskAdapter());
    }

    final encryptionKey = await _getOrCreateEncryptionKey();
    
    _metaBox = await Hive.openBox(_metaBoxName);
    _routinesBox = await Hive.openBox(_routinesBoxName);
    _activityBox = await Hive.openBox(_activityBoxName);
    _journalBox = await Hive.openBox(
      _journalBoxName, 
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  }

  Future<List<int>> _getOrCreateEncryptionKey() async {
    const secureStorage = FlutterSecureStorage();
    final encodedKey = await secureStorage.read(key: _secureKeyName);
    
    if (encodedKey == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: _secureKeyName, value: base64UrlEncode(key));
      return key;
    }
    
    return base64Url.decode(encodedKey);
  }

  Box _getBox(String? boxName) {
    switch (boxName) {
      case _routinesBoxName:
        return _routinesBox;
      case _activityBoxName:
        return _activityBox;
      case _journalBoxName:
        return _journalBox;
      case _metaBoxName:
      default:
        return _metaBox;
    }
  }

  @override
  T? get<T>(String key, {String? boxName}) {
    return _getBox(boxName).get(key) as T?;
  }

  @override
  Future<void> set<T>(String key, T value, {String? boxName}) async {
    await _getBox(boxName).put(key, value);
  }

  @override
  Future<void> remove(String key, {String? boxName}) async {
    await _getBox(boxName).delete(key);
  }

  @override
  List<String> getKeys({String? boxName}) {
    return _getBox(boxName).keys.cast<String>().toList();
  }

  @override
  Future<void> close() async {
    await Hive.close();
  }

  @override
  Future<String> exportData() async {
    final data = {
      'meta': {for (var k in _metaBox.keys) k.toString(): _metaBox.get(k)},
      'routines': {
        for (var k in _routinesBox.keys)
          k.toString(): _routinesBox.get(k) is List
              ? (_routinesBox.get(k) as List)
                  .map((e) => e is RoutineTask ? e.toJson() : e)
                  .toList()
              : _routinesBox.get(k)
      },
      'activity': {for (var k in _activityBox.keys) k.toString(): _activityBox.get(k)},
      'journal': {for (var k in _journalBox.keys) k.toString(): _journalBox.get(k)},
    };
    return jsonEncode(data);
  }

  @override
  Future<bool> importData(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      if (data.containsKey('meta')) {
        await _metaBox.clear();
        await _metaBox.putAll(data['meta'] as Map);
      }

      if (data.containsKey('routines')) {
        await _routinesBox.clear();
        final routines = data['routines'] as Map<String, dynamic>;
        for (var entry in routines.entries) {
          if (entry.value is List) {
            final list = (entry.value as List)
                .map((e) => RoutineTask.fromJson(e as Map<String, dynamic>))
                .toList();
            await _routinesBox.put(entry.key, list);
          } else {
            await _routinesBox.put(entry.key, entry.value);
          }
        }
      }

      if (data.containsKey('activity')) {
        await _activityBox.clear();
        await _activityBox.putAll(data['activity'] as Map);
      }

      if (data.containsKey('journal')) {
        await _journalBox.clear();
        await _journalBox.putAll(data['journal'] as Map);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
