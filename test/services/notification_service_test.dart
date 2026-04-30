import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bookend/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    notificationService = NotificationService(plugin: mockPlugin);

    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);

    // Mock platform channel for flutter_timezone
    const MethodChannel('flutter_timezone')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getLocalTimezone') {
        return 'UTC';
      }
      return null;
    });
  });

  group('NotificationService Initialization', () {
    test('initialize should call plugin initialize with correct settings',
        () async {
      // Arrange
      registerFallbackValue(const InitializationSettings());

      when(() => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).thenAnswer((_) async => true);

      // Act
      await notificationService.initialize();

      // Assert
      verify(() => mockPlugin.initialize(
            settings: any(named: 'settings'),
            onDidReceiveNotificationResponse:
                any(named: 'onDidReceiveNotificationResponse'),
          )).called(1);
    });
  });

  group('Nudge Chain Logic', () {
    test('scheduleNudgeChain should schedule 4 notifications with correct intervals',
        () async {
      // Arrange
      registerFallbackValue(tz.TZDateTime.now(tz.local));
      registerFallbackValue(const NotificationDetails());

      when(() => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: any(named: 'androidScheduleMode'),
            payload: any(named: 'payload'),
          )).thenAnswer((_) async => {});

      final startTime =
          DateTime.now().add(const Duration(hours: 1)); // 1 hour in future

      // Act
      await notificationService.scheduleNudgeChain(
        routineId: 'night_routine',
        startTime: startTime,
        title: 'Routine Time!',
      );

      // Assert
      verify(() => mockPlugin.zonedSchedule(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            scheduledDate: any(named: 'scheduledDate'),
            notificationDetails: any(named: 'notificationDetails'),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: any(named: 'payload'),
          )).called(4);
    });

    test('cancelNudgeChain should cancel all 4 notifications', () async {
      // Arrange
      when(() => mockPlugin.cancel(id: any(named: 'id'))).thenAnswer((_) async => {});

      // Act
      await notificationService.cancelNudgeChain('morning_routine');

      // Assert
      verify(() => mockPlugin.cancel(id: any(named: 'id'))).called(4);
    });
  });

  group('Permissions', () {
    test('requestPermissions should call platform specific request methods',
        () async {
      // Arrange
      final mockAndroidImplementation = MockAndroidFlutterLocalNotificationsPlugin();
      final mockIOSImplementation = MockIOSFlutterLocalNotificationsPlugin();

      when(() => mockPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>())
          .thenReturn(mockAndroidImplementation);
      when(() => mockPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>())
          .thenReturn(mockIOSImplementation);

      when(() => mockAndroidImplementation.requestNotificationsPermission())
          .thenAnswer((_) async => true);
      when(() => mockIOSImplementation.requestPermissions(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          )).thenAnswer((_) async => true);

      // Act
      await notificationService.requestPermissions();

      // Assert
      verify(() => mockAndroidImplementation.requestNotificationsPermission())
          .called(1);
      verify(() => mockIOSImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )).called(1);
    });
  });
}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}
