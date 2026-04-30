# Implementation Plan: Adaptive Pressure Notifications (\u0022The Owl Protocol\u0022)

Implement a high-intensity, behavior-driven notification system with escalating nudges and streak protection.

## Proposed Changes

### Phase 1: Infrastructure \u0026 Service
#### [MODIFY] [pubspec.yaml](file:///c:/Users/Darryl/.gemini/antigravity/scratch/bookend/pubspec.yaml)
- Add dependencies:
  - `flutter_local_notifications: ^17.0.0`
  - `timezone: ^0.11.0`
  - `flutter_timezone: ^5.0.2`

#### [NEW] [notification_service.dart](file:///c:/Users/Darryl/.gemini/antigravity/scratch/bookend/lib/services/notification_service.dart)
- Initialize `flutter_local_notifications`.
- Setup timezone handling.
- Implement `scheduleNudgeChain(String routineType, TimeOfDay goalTime)`:
  - Schedules N0 (Goal), N1 (+10m), N2 (+25m), N3 (+45m).
  - Uses `ID` ranges to avoid collisions (e.g., Morning: 100-103, Night: 200-203).
- Implement `cancelNudgeChain(String routineType)`.

### Phase 2: Repository \u0026 Logic
#### [MODIFY] [routine_repository.dart](file:///c:/Users/Darryl/.gemini/antigravity/scratch/bookend/lib/repositories/routine_repository.dart)
- Add `morningReminderTime` and `nightReminderTime` to storage.
- Add `markTaskCompleted` hook to trigger `cancelNudgeChain` if it\u0026#39;s the first task of the day.
- Add `markTaskPending` hook to reschedule nudges if no other tasks are completed.

#### [MODIFY] [time_service.dart](file:///c:/Users/Darryl/.gemini/antigravity/scratch/bookend/lib/services/time_service.dart)
- Add utility to check if a `goalTime` is still in the future for the current \u0022Effective Day\u0022.

### Phase 3: UI Integration
#### [MODIFY] [edit_routine_screen.dart](file:///c:/Users/Darryl/.gemini/antigravity/scratch/bookend/lib/screens/edit_routine_screen.dart)
- Add `Reminder Time` picker.
- Call `NotificationService` on save.

#### [MODIFY] [main.dart](file:///c:/Users/Darryl/.gemini/antigravity/scratch/bookend/lib/main.dart)
- Initialize `NotificationService` in `main()`.

---

## Task List

- [ ] **Task 1: Add Dependencies**
  - Run `flutter pub add flutter_local_notifications timezone flutter_timezone`
  - Verify `pubspec.yaml`
- [ ] **Task 2: Implement NotificationService Foundation**
  - Create `lib/services/notification_service.dart` with `initialize()` and `requestPermissions()`.
- [ ] **Task 3: Implement Owl Protocol Nudge Chain**
  - Add `scheduleNudgeChain` with the escalation levels (N0-N3).
  - Add `cancelNudgeChain` by ID ranges.
- [ ] **Task 4: Update RoutineRepository for Persistence**
  - Add `getReminderTime` and `setReminderTime`.
  - Add logic to track the first task completion.
- [ ] **Task 5: Integrate UI into EditRoutineScreen**
  - Add TimePicker and Save logic.
- [ ] **Task 6: Verification**
  - Set a reminder for 1 minute from now.
  - Verify N0 fires.
  - Complete 1 task.
  - Verify N1 does NOT fire.

## Verification Plan

### Automated Tests
- `notification_service_test.dart`: Mock `FlutterLocalNotificationsPlugin` and verify `zonedSchedule` is called 4 times for a chain.
- `routine_repository_test.dart`: Verify reminder times are saved to Hive correctly.

### Manual Verification
1. Set Morning Routine reminder to T+1 min.
2. Wait for N0.
3. Don\u0026#39;t click. Wait for N1 (+10m) - *Simulate by setting smaller intervals for testing*.
4. Complete 1 task.
5. Verify no more notifications appear.
