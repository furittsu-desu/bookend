import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Initialize Timezone Data
    tz.initializeTimeZones();
    final String timeZoneName =
        (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Initialize Notification Plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open App');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navigate to Focus screen
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Also request for iOS/macOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> scheduleNudgeChain({
    required String routineId,
    required DateTime startTime,
    required String title,
  }) async {
    final offsets = [0, 5, 15, 30];

    for (int i = 0; i < offsets.length; i++) {
      final scheduleTime = tz.TZDateTime.from(
        startTime.add(Duration(minutes: offsets[i])),
        tz.local,
      );

      // Only schedule if the time is in the future
      if (scheduleTime.isAfter(tz.TZDateTime.now(tz.local))) {
        await _plugin.zonedSchedule(
          id: routineId.hashCode + i,
          title: title,
          body: _getNudgeContent(i),
          scheduledDate: scheduleTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'nudge_channel',
              'Routine Nudges',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: routineId,
        );
      }
    }
  }

  String _getNudgeContent(int level) {
    final messages = [
      [
        'Ready for your routine? 📚',
        'Time to focus! 🚀',
        'Your routine is waiting... ✨',
      ],
      [
        'Routine started 5 mins ago. Still there? ⏳',
        'Don\'t fall behind! Start now. 🏃‍♂️',
        '5 minutes late. You can still do this! 💪',
      ],
      [
        '15 mins late! Don\'t break your streak! 🔥',
        'Consistency is key! Get moving. 🔑',
        'Warning: Streak at risk! ⚠️',
      ],
      [
        '30 mins late... Your habits are crying. 😢',
        'Are we really doing this? Just ONE task, please! 🙏',
        'Guilt trip incoming: Your future self is disappointed. 🤡',
      ],
    ];

    final levelMessages = messages[level];
    return levelMessages[DateTime.now().millisecond % levelMessages.length];
  }

  Future<void> cancelNudgeChain(String routineId) async {
    for (int i = 0; i < 4; i++) {
      await _plugin.cancel(id: routineId.hashCode + i);
    }
  }
}
