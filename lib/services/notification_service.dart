import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Android 13+: request notification permission
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    const channel = AndroidNotificationChannel(
      'tibia_tools_alerts',
      'Tibia Tools Alerts',
      description: 'Notificações de favoritos (online, morte, level up).',
      importance: Importance.high,
    );

    await android?.createNotificationChannel(channel);

    _inited = true;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'tibia_tools_alerts',
      'Tibia Tools Alerts',
      channelDescription: 'Notificações de favoritos',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }
}
