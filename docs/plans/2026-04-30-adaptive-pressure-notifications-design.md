# Design: Adaptive Pressure Notifications (\u0022The Owl Protocol\u0022)

## Overview
Implement a high-engagement notification system that uses behavioral psychology (Atomic Habits) and escalating pressure (Duolingo-style) to ensure routine adherence.

## 1. The Nudge Escalation (The \u0022Owl\u0022 Protocol)
Instead of a single notification, a sequence of nudges is scheduled.

| Step | Time | Tone | Example Content |
| :--- | :--- | :--- | :--- |
| **N0** | Goal Time | Encouraging | \u0022Time to win the day! First task: [Task Name] \u0022 |
| **N1** | +10 mins | Persistent | \u0022Don\u0026#39;t break the chain. Just 2 minutes? \u0022 |
| **N2** | +25 mins | Guilt-trip | \u0022Your streak is crying right now. Save it? \u0022 |
| **N3** | +45 mins | Intense | \u0022Even the is disappointed. Do ONE task to save the day! \u0022 |

## 2. The \u00222-Minute Rule\u0022 Logic
*   **Streak Protection**: Completing exactly **one** task from the routine satisfies the \u0022Showing Up\u0022 requirement for the day.
*   **Termination**: Marking the first task as completed immediately cancels all pending nudges for that routine.
*   **Undo Support**: If a task is unmarked (undone), the `NotificationService` re-evaluates the time and re-schedules pending nudges if the window is still open.

## 3. Adaptive Calibration (Bridge Goals)
*   **Detection**: App calculates a 7-day moving average of actual routine start times.
*   **Calibration**: If the gap between Goal and Average is \u003E 30 mins, the app suggests a **Bridge Goal** (e.g., 8:20 AM instead of 8:00 AM) to maintain motivation.

## 4. Technical Architecture
*   **NotificationService**: Centralizes all `flutter_local_notifications` logic.
*   **State Tracking**: `RoutineRepository` stores `last_start_time` and `reminder_config`.
*   **Platforms**:
    *   **Mobile**: Full implementation.
    *   **Windows**: Toast notifications.
    *   **Web**: Browser Notifications API (where supported).

## 5. Future Roadmap (Issue #20)
*   Weakest Link / Strongest Link insights.
*   Individual habit consistency scores.
*   Visual heatmaps of adherence.
