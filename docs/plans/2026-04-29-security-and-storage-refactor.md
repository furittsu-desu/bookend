# Security Hardening and Storage Refactoring Implementation Plan

> **For Antigravity:** REQUIRED SUB-SKILL: Load executing-plans to implement this plan task-by-task.

**Goal:** Remove security vulnerabilities and improve architectural maintainability by securing encryption keys and refactoring storage logic.

**Architecture:** 
1. **Security Layer**: Introduce `EncryptionService` using `flutter_secure_storage` to manage dynamic AES keys.
2. **Logic Layer**: Extract time-dependent reset logic into a mockable `TimeService`.
3. **Data Layer**: Decompose `StorageService` into `RoutineRepository` (tasks/journals) and `MetricsRepository` (focus data) to satisfy SRP.

**Tech Stack:** 
- Flutter / Dart
- `flutter_secure_storage` (New)
- `encrypt` (Existing)
- `shared_preferences` (Existing)

---

### Task 1: Environment Setup
**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependencies**
Run: `flutter pub add flutter_secure_storage`
Expected: `pubspec.yaml` updated with `flutter_secure_storage: ^9.2.4` (or latest).

**Step 2: Install packages**
Run: `flutter pub get`
Expected: Success.

---

### Task 2: Implement EncryptionService [NEW]
**Files:**
- Create: `lib/services/encryption_service.dart`

**Step 1: Define EncryptionService**
Create a service that manages a 32-character key in secure storage.

```dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).substring(0, 32);
  }
}
```

---

### Task 3: Implement TimeService [NEW]
**Files:**
- Create: `lib/services/time_service.dart`

**Step 1: Extract reset logic**
Define a service that encapsulates the "4:00 AM" date calculation.

```dart
class TimeService {
  DateTime now() => DateTime.now();

  DateTime getEffectiveDate() {
    final currentTime = now();
    if (currentTime.hour < 4) {
      return currentTime.subtract(const Duration(days: 1));
    }
    return currentTime;
  }

  String getEffectiveDateString() {
    final date = getEffectiveDate();
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
```

---

### Task 4: Refactor StorageService - Security Update
**Files:**
- Modify: `lib/services/storage_service.dart`

**Step 1: Update Encryption Logic**
Remove `_encryptionKey` and initialize `EncryptionService`.

```dart
// Remove: static const String _encryptionKey = '...';

// Add:
final EncryptionService _encryptionService = EncryptionService();
String? _cachedKey;

Future<String> _getEncryptionKey() async {
  _cachedKey ??= await _encryptionService.getOrGenerateKey();
  return _cachedKey!;
}
```

**Step 2: Update Encrypt/Decrypt methods**
Make them asynchronous to fetch the key.

---

### Task 5: Decomposition into Repositories [PHASED]
**Files:**
- Create: `lib/repositories/routine_repository.dart`
- Create: `lib/repositories/metrics_repository.dart`
- Modify: `lib/main.dart`

**Step 1: Create RoutineRepository**
Move `loadTasks`, `saveTasks`, `loadJournal`, `saveJournal` to this repository.

**Step 2: Create MetricsRepository**
Move `loadRoutineMetrics`, `saveRoutineMetrics` and focus logic here.

**Step 3: Update Dependency Injection in main.dart**
Pass new services to relevant UI components.

---

### Verification Plan

**Manual Verification:**
1. Run app and complete a task.
2. Verify task status persists across restarts (Encryption working).
3. Change system time to 3:00 AM and verify metrics still count for "yesterday" (TimeService working).

**Automated Tests:**
Run: `flutter test`
Expected: All existing tests pass. (New tests for TimeService recommended).
