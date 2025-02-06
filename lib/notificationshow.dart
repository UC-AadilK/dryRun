import 'dart:async';
import 'package:flutter/services.dart' ;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void backgroundNotificationResponseHandler(NotificationResponse notification) async {
  print('Received background notification response: $notification');
}

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationPlugin = FlutterLocalNotificationsPlugin();

  // Method to initialize notifications.
  Future<void> initNotification() async {
    // Android-specific initialization settings. Replace 'logo' with your drawable resource name.
    const AndroidInitializationSettings initializationAndroidSettings = AndroidInitializationSettings('logo');

    // iOS-specific initialization settings.
    final DarwinInitializationSettings initializationSettingIOS = DarwinInitializationSettings(
      requestAlertPermission: true,  // Request permission to show alerts.
      defaultPresentSound: true,      // Enable default sound for notifications.
      defaultPresentAlert: true,      // Show alerts by default.
      requestBadgePermission: true,   // Request permission to use badges.
      requestSoundPermission: true,   // Request permission to play sounds.
      // This callback is triggered when a local notification is received while the app is in the foreground.
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        print('Received local notification in iOS: $id, $title, $body, $payload');
      },
    );

    // Combine Android and iOS settings into one initialization settings object.
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationAndroidSettings,
      iOS: initializationSettingIOS,
    );

    // Initialize the notifications plugin with the provided settings.
    await notificationPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: backgroundNotificationResponseHandler,
    );
  }

  // Method to show a notification.
  Future<void> showNotification({
    int id = 0,             // Notification ID (default is 0).
    String? title,         // Notification title.
    String? body,          // Notification body text.
    String? payload,       // Optional payload to be passed when notification is tapped.
    String? type,
  }) async {
    print('Showing notification: $id, $title, $body, $payload');
    try {
      // Show the notification with the specified details.
      await notificationPlugin.show(
        id,
        title,
        body,
        await notificationDetails(), // Call to get the notification details.
        payload: payload,
      );
    } catch (e) {
      // Catch any errors that occur while showing the notification.
      print('Error showing notification: $e');
    }
  }

  // Method to configure the notification details.
  Future<NotificationDetails> notificationDetails() async {

    // Return the notification details, specifying settings for both iOS and Android.
    return const NotificationDetails(
      iOS:  DarwinNotificationDetails(), // Default settings for iOS notifications.
      android: AndroidNotificationDetails(
        'channelId',         // Unique channel ID for notifications.
        'channelName',       // Human-readable name for the channel.
        importance: Importance.max, // Highest importance for notifications.
        priority: Priority.high, // High priority for notifications.
      ),
    );
  }
}
