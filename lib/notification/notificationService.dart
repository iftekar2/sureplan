import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notificationservice {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  // Initialize Notification
  Future<void> initialize() async {
    if (_initialized) return;

    // prepare android initialization settings
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // prepare ios initialization settings
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // prepare initialization settings
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // initialize the plugin
    await notificationPlugin.initialize(initializationSettings);

    // Request Android 13+ permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // Notification details
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),

      iOS: DarwinNotificationDetails(),
    );
  }

  // Show Notification
  Future<void> showNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    return notificationPlugin.show(
      id.hashCode,
      title,
      body,
      notificationDetails(),
    );
  }
}
