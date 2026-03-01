import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Notification පද්ධතිය සූදානම් කිරීම (Initialization)
  static Future<void> initNotification() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // --- මෙන්න වැරැද්ද නිවැරදි කළ තැන (LINE 26-27 FIX) ---
    // ඔයාගේ Error එකට අනුව මෙතැන 'settings:' ලෙස නම දිය යුතුමයි
    await _notificationsPlugin.initialize(settings: initSettings);
  }

  // 2. සජීවීව Notification එක පෙන්වීම (Display Logic)
  static Future<void> showSOSNotification(String type, String address) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true, // ensure sound plays on iOS
        subtitle: 'SafePulse Security Alert',
      ),
      android: AndroidNotificationDetails(
        'sos_channel_id',
        'Emergency Alerts',
        channelDescription: 'Notifications for SOS Alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true, // explicitly enable sound on Android
      ),
    );

    // --- මෙතනත් 'id:', 'title:' ආදී නම් (Named Arguments) භාවිතා කර ඇත ---
    await _notificationsPlugin.show(
      id: 0,
      title: "🆘 SOS TRIGGERED",
      body: "Immediate help needed for $type at $address",
      notificationDetails: details,
    );
  }
}
