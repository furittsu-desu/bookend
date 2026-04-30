# Local Database Migration (Hive) Implementation Plan

> **For Antigravity:** REQUIRED SUB-SKILL: Load executing-plans to implement this plan task-by-task.

**Goal:** Migrate Bookend storage from `SharedPreferences` to Hive with encryption and migration support.

**Architecture:** Repository pattern abstraction using a `BaseStorage` interface, with a `HiveStorageService` implementation and a `StorageMigrationService` for the transition.

**Tech Stack:** Flutter, Hive, Hive Flutter, Flutter Secure Storage, Path Provider.

---

### Task 1: Project Dependencies & Base Interface
Add required packages and define the storage abstraction.

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/storage_service.dart`

**Step 1: Add dependencies**
Run: `flutter pub add hive hive_flutter path_provider`
Run: `flutter pub add --dev hive_generator build_runner`

**Step 2: Create BaseStorage interface**
```dart
abstract class BaseStorage {
  Future<void> init();
  T? get<T>(String key, {String? boxName});
  Future<void> set<T>(String key, T value, {String? boxName});
  Future<void> remove(String key, {String? boxName});
  List<String> getKeys({String? boxName});
}
```

**Step 3: Commit**
```bash
git commit -m "feat: add storage dependencies and base interface"
```

### Task 2: RoutineTask Model Migration
Update the model to support Hive serialization.

**Files:**
- Modify: `lib/models/routine_task.dart`
- Create: `lib/models/routine_task.g.dart` (generated)

**Step 1: Add Hive annotations**
```dart
import 'package:hive/hive.dart';
part 'routine_task.g.dart';

@HiveType(typeId: 0)
class RoutineTask {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  // ... (apply to all fields)
}
```

**Step 2: Generate Adapter**
Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 3: Commit**
```bash
git commit -m "feat: add hive annotations to RoutineTask"
```

### Task 3: Encryption & Hive Implementation
Implement the `HiveStorageService` with secure key management.

**Files:**
- Create: `lib/services/hive_storage_service.dart`

**Step 1: Implement HiveStorageService**
- Initialize Hive using `Hive.initFlutter()`.
- Register `RoutineTaskAdapter`.
- Manage encryption key via `FlutterSecureStorage`.
- Open boxes: `meta`, `routines`, `activity`, `journal` (encrypted).

**Step 2: Commit**
```bash
git commit -m "feat: implement HiveStorageService with encryption"
```

### Task 4: Storage Migration Service
Implement the bridge to pull data from `SharedPreferences`.

**Files:**
- Create: `lib/services/storage_migration_service.dart`

**Step 1: Implement migration logic**
- Check `meta` box for `migration_completed`.
- If false, read all keys from `SharedPreferences`.
- Map keys to appropriate Hive boxes.
- Close `SharedPreferences` and set `migration_completed = true`.

**Step 2: Commit**
```bash
git commit -m "feat: add StorageMigrationService"
```

### Task 5: RoutineRepository Refactor
Update the repository to use the new storage abstraction.

**Files:**
- Modify: `lib/repositories/routine_repository.dart`

**Step 1: Replace SharedPreferences with BaseStorage**
- Update constructor.
- Replace `_prefs.getString/setBool` etc. with `_storage.get/set`.
- Remove manual JSON encoding for `RoutineTask` as Hive handles it via adapters.

**Step 2: Commit**
```bash
git commit -m "refactor: update RoutineRepository to use BaseStorage"
```

### Task 6: Global Initialization
Wire everything up in `main.dart`.

**Files:**
- Modify: `lib/main.dart`

**Step 1: Initialize services**
- Initialize `HiveStorageService`.
- Run `StorageMigrationService`.
- Inject `StorageService` into `RoutineRepository`.

**Step 2: Commit**
```bash
git commit -m "feat: initialize hive storage and migration in main.dart"
```

### Task 7: Verification
Run tests and verify data integrity.

**Step 1: Update existing tests**
- Update `routine_repository_test.dart` to use a Mock storage service.

**Step 2: Run all tests**
Run: `flutter test`
Expected: ALL PASS

**Step 3: Final Commit**
```bash
git commit -m "test: verify hive migration and repository refactor"
```
