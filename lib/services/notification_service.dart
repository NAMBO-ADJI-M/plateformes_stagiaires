import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'internship_service.dart';
import 'pointage_event_bus.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  // Le payload peut être un carnetId ou un autorisationId
  // On tente de le traiter comme une autorisation si c'est possible
  try {
    if (response.actionId == 'action_pause') {
      await InternshipService().confirmerPause(autorisationId: payload);
      PointageEventBus().notifyPointageUpdate();
    } else if (response.actionId == 'action_depart') {
      await InternshipService().confirmerDepart(autorisationId: payload);
      PointageEventBus().notifyPointageUpdate();
    }
  } catch (_) {
    // Repli sur carnetId si autorisation échoue (pour compatibilité)
    try {
      if (response.actionId == 'action_pause') {
        await InternshipService().confirmerPause(carnetId: payload);
        PointageEventBus().notifyPointageUpdate();
      } else if (response.actionId == 'action_depart') {
        await InternshipService().confirmerDepart(carnetId: payload);
        PointageEventBus().notifyPointageUpdate();
      }
    } catch (__) {}
  }
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geofence_channel',
      'Pointage Automatique',
      channelDescription: 'Notifications de confirmation de pointage GPS',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics, payload: payload);
  }

  Future<void> showExitChoiceNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geofence_channel',
      'Pointage Automatique',
      channelDescription: 'Notifications de confirmation de pointage GPS',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_pause',
          '☕ Pause',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'action_depart',
          '🏠 Fin de journée',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<void> _onNotificationAction(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      if (response.actionId == 'action_pause') {
        await InternshipService().confirmerPause(autorisationId: payload);
        PointageEventBus().notifyPointageUpdate();
      } else if (response.actionId == 'action_depart') {
        await InternshipService().confirmerDepart(autorisationId: payload);
        PointageEventBus().notifyPointageUpdate();
      }
    } catch (_) {
      try {
        if (response.actionId == 'action_pause') {
          await InternshipService().confirmerPause(carnetId: payload);
          PointageEventBus().notifyPointageUpdate();
        } else if (response.actionId == 'action_depart') {
          await InternshipService().confirmerDepart(carnetId: payload);
          PointageEventBus().notifyPointageUpdate();
        }
      } catch (__) {}
    }
  }
}
