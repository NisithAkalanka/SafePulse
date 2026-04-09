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

  /// Local alert shown to requester when a helper offers help.
  static Future<void> showHelpOfferNotification({
    required int id,
    required String helperName,
    required String category,
    required String title,
  }) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: 'SafePulse Help Offer',
      ),
      android: AndroidNotificationDetails(
        'help_offer_channel_id',
        'Help Offers',
        channelDescription: 'Notifications when helpers offer to assist',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: 'New helper offer',
      body: '$helperName offered help for $category: $title',
      notificationDetails: details,
    );
  }

  /// Local alert shown to helper when their offer is accepted.
  static Future<void> showHelpAcceptedNotification({
    required int id,
    required String category,
    required String title,
  }) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: 'Help Offer Accepted',
      ),
      android: AndroidNotificationDetails(
        'help_accepted_channel_id',
        'Help Accepted Alerts',
        channelDescription: 'Notifications when your help offer is accepted',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: 'Your Help Has been Accepted',
      body: 'You can now start a private chat for $category: $title',
      notificationDetails: details,
    );
  }

  // Safe status notification (when user is marked safe)
  static Future<void> showSafeNotification(String userName) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      android: AndroidNotificationDetails(
        'safe_channel',
        'Safety Alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    await _notificationsPlugin.show(
      id: 1,
      title: "✅ STATUS UPDATE",
      body: "$userName is now Safe. Crisis resolved.",
      notificationDetails: details,
    );
  }
}
