import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // navigatorKey එක පාවිච්චි කිරීමට
import '../screens/sos_system/group_chat_screen.dart'; // Chat Screen එකට යාමට

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Notification පද්ධතිය සූදානම් කිරීම (Initialization)
  static Future<void> initNotification() async {
    // Android 13+ සඳහා Permission ඉල්ලීම
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/Darwin සඳහා විශේෂ සැකසුම්
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

    // --- මෙන්න මෙතන තමයි වැරැද්ද නිවැරදි කළේ (settings: ලෙස ලබා දිය යුතුයි) ---
    await _notificationsPlugin.initialize(
      settings: initSettings, // 'settings:' යන්න අනිවාර්ය වේ
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // නොටිෆිකේෂන් එක ක්ලික් කළාම මේ කොටස වැඩ කරයි
        if (response.payload != null && response.payload!.isNotEmpty) {
          // Payload එකේ තියෙන groupId එක අරන් Chat එකට යනවා
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => GroupChatScreen(groupId: response.payload!),
            ),
          );
        }
      },
    );
  }

  // --- 2. ගෲප් චැට් මැසේජ් පෙන්වීමට ---
  static Future<void> showChatNotification({
    required int id,
    required String groupName,
    required String senderName,
    required String message,
    required String groupId,
  }) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: 'New Message',
        interruptionLevel: InterruptionLevel.active,
      ),
      android: AndroidNotificationDetails(
        'chat_v3',
        'Group Messages',
        channelDescription: 'Notifications for protection circle messages',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: id,
      title: groupName,
      body: "$senderName: $message",
      notificationDetails: details,
      payload: groupId, // ක්ලික් කළාම හඳුනාගැනීමට ID එක යවනවා
    );
  }

  // --- 3. SOS Notification (කලින් තිබූ කේතයම වේ) ---
  static Future<void> showSOSNotification(String type, String address) async {
    const NotificationDetails details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: 'SafePulse Security Alert',
      ),
      android: AndroidNotificationDetails(
        'sos_channel_id',
        'Emergency Alerts',
        channelDescription: 'Notifications for SOS Alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    await _notificationsPlugin.show(
      id: 0,
      title: "🆘 SOS TRIGGERED",
      body: "Immediate help needed for $type at $address",
      notificationDetails: details,
    );
  }

  // --- 4. Help Offer Notification (කලින් තිබූ කේතයම වේ) ---
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

  // --- 5. Help Accepted Notification (කලින් තිබූ කේතයම වේ) ---
  static Future<void> showHelpAcceptedNotification({
    required int id,
    required String category,
    required String title,
    String? helperBadge,
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
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    );

    final normalizedBadge = (helperBadge ?? '').trim().toLowerCase();
    final badgeLine = normalizedBadge.isNotEmpty
        ? ' Your helper has a $normalizedBadge badge.'
        : '';

    await _notificationsPlugin.show(
      id: id,
      title: 'Help Accepted',
      body:
          'Your help offer for $category: $title has been accepted.$badgeLine',
      notificationDetails: details,
    );
  }

  // --- 6. Safe Status Notification (කලින් තිබූ කේතයම වේ) ---
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
