import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

//credit to https://www.youtube.com/watch?v=xOv3yyN2HKw

class NotificationManager {
  FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationManager() {
    initNotification();
  }

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');
    DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) {
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    print("Scheduling notification at $scheduledTime with title $title");
    var androidDetails = const AndroidNotificationDetails(
        'scheduled_channel_id', 'scheduled_channel_name',
        importance: Importance.max, priority: Priority.high);
    var iOSDetails = const DarwinNotificationDetails();
    var platformDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await notificationsPlugin.zonedSchedule(id, title, body,
        tz.TZDateTime.from(scheduledTime, tz.local), platformDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
    print("Notification scheduled");
  }
}
